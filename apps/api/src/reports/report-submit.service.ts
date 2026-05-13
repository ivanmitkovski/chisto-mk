import { Injectable, Logger } from '@nestjs/common';
import {
  AdminNotificationCategory,
  AdminNotificationTone,
  Prisma,
  ReportCleanupEffort,
} from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CreateReportWithLocationDto } from './dto/create-report-with-location.dto';
import { ReportSubmitResponseDto } from './dto/report-submit-response.dto';
import { ReportCapacityService } from './report-capacity.service';
import { ReportSubmitPostCreateEventsService } from './report-submit-post-create-events.service';
import { ReportSubmitIdempotencyService } from './report-submit-idempotency.service';
import { ReportSubmitMediaAppendService } from './report-submit-media-append.service';
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
    private readonly idempotency: ReportSubmitIdempotencyService,
    private readonly mediaAppend: ReportSubmitMediaAppendService,
  ) {}

  async createWithLocation(
    user: AuthenticatedUser,
    dto: CreateReportWithLocationDto,
    headerIdempotencyKey?: string | string[],
    locale: ReportSubmitLocale = 'mk',
    requestId?: string,
  ): Promise<ReportSubmitResponseDto> {
    const startedAt = Date.now();
    const trimmedIdem = this.idempotency.parseIdempotencyKeyHeader(headerIdempotencyKey);
    if (trimmedIdem) {
      const replay = await this.idempotency.tryReplayFromIdempotencyKey(user.userId, trimmedIdem);
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

  appendMedia(reportId: string, userId: string, urls: string[]): Promise<void> {
    return this.mediaAppend.appendMedia(reportId, userId, urls);
  }
}
