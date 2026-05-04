import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  AdminNotificationCategory,
  AdminNotificationTone,
  Prisma,
  ReportCleanupEffort,
} from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { REASON_REPORT_APPROVED, REASON_REPORT_SUBMITTED } from '../gamification/gamification.constants';
import { CreateReportWithLocationDto } from './dto/create-report-with-location.dto';
import { ReportSubmitResponseDto } from './dto/report-submit-response.dto';
import { ReportCapacityService } from './report-capacity.service';
import { ReportSubmitPostCreateEventsService } from './report-submit-post-create-events.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import { parseReportCleanupEffort } from './report-cleanup-effort';
import { NearbySiteForReportSubmitResolver } from './site-resolution/nearby-site-for-report-submit.resolver';
import { adminSubmitNotificationCopy, getReportNumber } from './report-copy.helpers';
import type { ReportSubmitLocale } from './report-locale.util';
import { ObservabilityStore } from '../observability/observability.store';
import { ReportsUploadService } from './reports-upload.service';

@Injectable()
export class ReportSubmitService {
  private readonly logger = new Logger(ReportSubmitService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly postCreateEvents: ReportSubmitPostCreateEventsService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
    private readonly reportCapacity: ReportCapacityService,
    private readonly reportsUpload: ReportsUploadService,
    private readonly nearbySiteResolver: NearbySiteForReportSubmitResolver,
  ) {}

  private static readonly IDEMPOTENCY_KEY_PATTERN = /^[A-Za-z0-9_-]{16,128}$/;

  /**
   * Returns a validated key, or `null` when the header is absent / whitespace-only.
   * Throws when a non-empty header does not match the allowed shape.
   */
  private parseIdempotencyKeyHeader(header: string | string[] | undefined): string | null {
    if (header === undefined) {
      return null;
    }
    const raw = Array.isArray(header) ? header[0] : header;
    const t = raw.trim();
    if (!t) {
      return null;
    }
    if (!ReportSubmitService.IDEMPOTENCY_KEY_PATTERN.test(t)) {
      throw new BadRequestException({
        code: 'INVALID_IDEMPOTENCY_KEY',
        message: 'Idempotency-Key must be 16–128 characters and match [A-Za-z0-9_-].',
      });
    }
    return t;
  }

  private async resolveIdempotentReportSubmit(
    userId: string,
    key: string,
  ): Promise<ReportSubmitResponseDto | null> {
    const row = await this.prisma.reportSubmitIdempotency.findUnique({
      where: { userId_key: { userId, key } },
      select: { reportId: true },
    });
    if (!row) {
      return null;
    }
    const report = await this.prisma.report.findUnique({
      where: { id: row.reportId },
      select: {
        id: true,
        siteId: true,
        reportNumber: true,
        createdAt: true,
        reporterId: true,
      },
    });
    if (!report || report.reporterId !== userId) {
      return null;
    }
    const ledger = await this.submitPointsFromLedger(userId, report.id);
    return {
      reportId: report.id,
      reportNumber: getReportNumber(report),
      siteId: report.siteId,
      isNewSite: false,
      pointsAwarded: ledger.pointsAwarded,
      ...(ledger.pointsBreakdown != null ? { pointsBreakdown: ledger.pointsBreakdown } : {}),
    };
  }

  private async submitPointsFromLedger(
    userId: string,
    reportId: string,
  ): Promise<{
    pointsAwarded: number;
    pointsBreakdown?: Array<{ code: string; points: number }>;
  }> {
    const txns = await this.prisma.pointTransaction.findMany({
      where: { userId, referenceType: 'Report', referenceId: reportId },
      select: { delta: true, metadata: true, reasonCode: true },
      orderBy: { createdAt: 'asc' },
    });
    const net = txns.reduce((sum, row) => sum + row.delta, 0);
    const approved = txns.find((t) => t.reasonCode === REASON_REPORT_APPROVED);
    const legacySubmit = txns.find((t) => t.reasonCode === REASON_REPORT_SUBMITTED);
    const metaSource = approved ?? legacySubmit;
    const meta = metaSource?.metadata as { breakdown?: Array<{ code: string; points: number }> } | null;
    const breakdown = Array.isArray(meta?.breakdown) ? meta!.breakdown : undefined;
    return {
      pointsAwarded: Math.max(0, net),
      ...(breakdown != null ? { pointsBreakdown: breakdown } : {}),
    };
  }

  async createWithLocation(
    user: AuthenticatedUser,
    dto: CreateReportWithLocationDto,
    headerIdempotencyKey?: string | string[],
    locale: ReportSubmitLocale = 'mk',
    requestId?: string,
  ): Promise<ReportSubmitResponseDto> {
    const startedAt = Date.now();
    const trimmedIdem = this.parseIdempotencyKeyHeader(headerIdempotencyKey);
    if (trimmedIdem) {
      const replay = await this.resolveIdempotentReportSubmit(user.userId, trimmedIdem);
      if (replay) {
        ObservabilityStore.recordReportSubmit('success', Date.now() - startedAt);
        this.logger.log(
          JSON.stringify({
            scope: 'report_submit',
            outcome: 'idempotent_replay',
            requestId: requestId ?? null,
            reportId: replay.reportId,
            durationMs: Date.now() - startedAt,
          }),
        );
        return replay;
      }
    }

    try {
    this.reportsUpload.assertReportMediaUrlsFromOurBucket(dto.mediaUrls);
    const submitLocale: ReportSubmitLocale = locale;
    const { latitude, longitude, title, description, mediaUrls, category, severity, address } = dto;
    const trimmedAddress = address?.trim() || null;
    const cleanupEffortParsed: ReportCleanupEffort | null = parseReportCleanupEffort(
      dto.cleanupEffort,
    );
    const primaryReport = await this.nearbySiteResolver.resolveEarliestReportAnchor(
      latitude,
      longitude,
    );
    const targetSiteId = primaryReport?.siteId ?? null;

    const result = await this.prisma.$transaction(async (tx) => {
      await this.reportCapacity.spendWithinTransaction(tx, user.userId, new Date());

      let siteId: string;
      let isNewSite: boolean;
      let siteUpdatedAt: Date | null = null;

      if (targetSiteId) {
        siteId = targetSiteId;
        isNewSite = false;
        if (trimmedAddress) {
          await tx.site.updateMany({
            where: { id: targetSiteId, address: null },
            data: { address: trimmedAddress },
          });
        }
      } else {
        const newSite = await tx.site.create({
          data: {
            latitude,
            longitude,
            address: trimmedAddress,
            description: null,
          },
        });
        siteId = newSite.id;
        isNewSite = true;
        siteUpdatedAt = newSite.updatedAt;
      }

      const newReport = await tx.report.create({
        data: {
          siteId,
          title: title.trim(),
          description: description?.trim() || null,
          mediaUrls: mediaUrls ?? [],
          reporterId: user.userId,
          potentialDuplicateOfId: primaryReport?.id ?? null,
          category: category ?? null,
          severity: severity ?? null,
          cleanupEffort: cleanupEffortParsed,
        },
      });

      if (
        primaryReport &&
        primaryReport.reporterId &&
        primaryReport.reporterId !== user.userId
      ) {
        await tx.reportCoReporter.upsert({
          where: {
            reportId_userId: {
              reportId: primaryReport.id,
              userId: user.userId,
            },
          },
          update: {},
          create: {
            reportId: primaryReport.id,
            userId: user.userId,
            reportedAt: newReport.createdAt,
          },
        });
      }

      const reportNumber = getReportNumber(newReport);
      const notifCopy = adminSubmitNotificationCopy({
        locale: submitLocale,
        isNewSite,
        reportNumber,
      });

      const notification = await tx.adminNotification.create({
        data: {
          title: notifCopy.title,
          message: notifCopy.message,
          timeLabel: notifCopy.timeLabel,
          tone: AdminNotificationTone.info,
          category: AdminNotificationCategory.reports,
          href: `/dashboard/reports?reportId=${newReport.id}`,
          messageTemplateKey: isNewSite ? 'reports.submitted.new_site' : 'reports.submitted.co_report',
          messageTemplateParams: { reportNumber } as Prisma.InputJsonValue,
        },
      });

      if (trimmedIdem) {
        await tx.reportSubmitIdempotency.create({
          data: {
            userId: user.userId,
            key: trimmedIdem,
            reportId: newReport.id,
          },
        });
      }

      return {
        reportId: newReport.id,
        reportNumber: getReportNumber(newReport),
        siteId,
        isNewSite,
        pointsAwarded: 0,
        siteUpdatedAt,
        notificationId: notification.id,
        notificationTitle: notification.title,
      };
    });

    if (trimmedIdem) {
      this.reportsOwnerEventsService.emit(user.userId, result.reportId, 'report_submit_queued', {
        kind: 'submit_queued',
        idempotencyKey: trimmedIdem,
      });
    }

    this.postCreateEvents.emit({
      userId: user.userId,
      reportId: result.reportId,
      siteId: result.siteId,
      isNewSite: result.isNewSite,
      notificationId: result.notificationId,
      notificationTitle: result.notificationTitle,
      siteUpdatedAt: result.siteUpdatedAt,
      latitude,
      longitude,
    });
    ObservabilityStore.recordReportSubmit('success', Date.now() - startedAt);
    this.logger.log(
      JSON.stringify({
        scope: 'report_submit',
        outcome: 'success',
        requestId: requestId ?? null,
        reportId: result.reportId,
        siteId: result.siteId,
        isNewSite: result.isNewSite,
        idempotencyKey: trimmedIdem ?? null,
        durationMs: Date.now() - startedAt,
      }),
    );

    return {
      reportId: result.reportId,
      reportNumber: result.reportNumber,
      siteId: result.siteId,
      isNewSite: result.isNewSite,
      pointsAwarded: 0,
    };
    } catch (err) {
      ObservabilityStore.recordReportSubmit('error');
      this.logger.warn(
        JSON.stringify({
          scope: 'report_submit',
          outcome: 'error',
          requestId: requestId ?? null,
          idempotencyKey: trimmedIdem ?? null,
          durationMs: Date.now() - startedAt,
        }),
      );
      throw err;
    }
  }

  /**
   * Appends media URLs to an existing report. Only the report's reporter or co-reporters may add media.
   */
  async appendMedia(reportId: string, userId: string, urls: string[]): Promise<void> {
    if (!urls || urls.length === 0) {
      return;
    }
    this.reportsUpload.assertReportMediaUrlsFromOurBucket(urls);

    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        reporterId: true,
        mediaUrls: true,
        coReporters: { select: { userId: true } },
      },
    });

    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    const isReporter = report.reporterId === userId;
    const isCoReporter = report.coReporters.some((c) => c.userId === userId);
    if (!isReporter && !isCoReporter) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Only the report creator or co-reporters may add media',
      });
    }

    const existingUrls = report.mediaUrls ?? [];
    const newUrls = [...existingUrls, ...urls];
    if (newUrls.length > 10) {
      throw new BadRequestException({
        code: 'TOO_MANY_MEDIA',
        message: 'Maximum 10 media files per report',
      });
    }

    await this.prisma.report.update({
      where: { id: reportId },
      data: { mediaUrls: newUrls },
    });

    const coReporterUserIds = report.coReporters.map((c) => c.userId);
    this.reportsOwnerEventsService.emitToReportInterestedParties(
      reportId,
      report.reporterId,
      coReporterUserIds,
      'report_updated',
      { kind: 'media_appended' },
    );
  }
}
