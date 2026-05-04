import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import {
  Prisma,
  Report,
  ReportSideEffectKind,
  ReportSideEffectStatus,
  ReportStatus,
  SiteStatus,
} from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  AdminReportDetailDto,
  AdminReportListItemDto,
  AdminReportListResponseDto,
} from './dto/admin-report.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { ReportsUploadService } from './reports-upload.service';
import { reportCleanupEffortLabel } from './report-cleanup-effort';
import { ReportApprovalPointsService } from './report-approval-points.service';
import {
  displayReportTitle,
  getReportNumber,
  listLocationLabel,
  optionalReportNarrative,
} from './report-copy.helpers';
import { deriveAdminReportDetailPriority } from './report-moderation-priority.helper';
import { moderationQueueMetaForStatus } from './report-moderation-queue-meta';
import { transitionSiteToVerifiedIfFirstApproved } from './report-site-verification.helper';
import { ReportSideEffectProcessorService } from './side-effects/report-side-effect-processor.service';
import type { ModerationStatusSideEffectPayload } from './side-effects/report-side-effect-processor.service';

const ALLOWED_REPORT_STATUS_TRANSITIONS: Record<ReportStatus, ReportStatus[]> = {
  NEW: ['IN_REVIEW', 'APPROVED', 'DELETED'],
  IN_REVIEW: ['APPROVED', 'DELETED'],
  APPROVED: ['DELETED'],
  DELETED: [],
};

@Injectable()
export class ReportsModerationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly reportApprovalPoints: ReportApprovalPointsService,
    private readonly reportSideEffectProcessor: ReportSideEffectProcessorService,
  ) {}

  async findAllForModeration(query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    const where: Prisma.ReportWhereInput = {
      ...(query.status ? { status: query.status } : {}),
      ...(query.siteId ? { siteId: query.siteId } : {}),
      ...(query.duplicatesOnly
        ? {
            OR: [{ potentialDuplicateOfId: { not: null } }, { potentialDuplicates: { some: {} } }],
          }
        : {}),
    };

    const skip = (query.page - 1) * query.limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.report.findMany({
        where,
        skip,
        take: query.limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          createdAt: true,
          reportNumber: true,
          title: true,
          description: true,
          category: true,
          status: true,
          cleanupEffort: true,
          potentialDuplicateOfId: true,
          site: {
            select: {
              id: true,
              status: true,
              latitude: true,
              longitude: true,
              description: true,
              address: true,
            },
          },
          coReporters: { select: { userId: true } },
          potentialDuplicates: {
            select: { id: true },
          },
        },
      }),
      this.prisma.report.count({ where }),
    ]);

    const items: AdminReportListItemDto[] = data.map((report) => ({
      id: report.id,
      reportNumber: getReportNumber(report),
      name: displayReportTitle(report),
      location: report.site
        ? listLocationLabel(report.site, report.description)
        : 'Unknown location',
      dateReportedAt: report.createdAt.toISOString(),
      status: report.status,
      isPotentialDuplicate:
        report.potentialDuplicateOfId !== null || report.potentialDuplicates.length > 0,
      coReporterCount: report.coReporters.length,
      cleanupEffortLabel: reportCleanupEffortLabel(report.cleanupEffort),
    }));

    return {
      data: items,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
      },
    };
  }

  async updateStatus(
    reportId: string,
    dto: UpdateReportStatusDto,
    moderator: AuthenticatedUser,
  ): Promise<Report> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        status: true,
        reporterId: true,
        siteId: true,
        coReporters: { select: { userId: true } },
      },
    });

    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    if (report.status === dto.status) {
      return this.prisma.report.findUniqueOrThrow({
        where: { id: reportId },
      });
    }

    const allowedStatuses = ALLOWED_REPORT_STATUS_TRANSITIONS[report.status];
    if (!allowedStatuses.includes(dto.status)) {
      throw new BadRequestException({
        code: 'INVALID_REPORT_STATUS_TRANSITION',
        message: `Cannot transition report status from '${report.status}' to '${dto.status}'`,
        details: {
          from: report.status,
          to: dto.status,
          allowedTo: allowedStatuses,
        },
      });
    }

    const now = new Date();

    const updatedResult = await this.prisma.$transaction(async (tx) => {
      const updatedReport = await tx.report.update({
        where: { id: reportId },
        data: {
          status: dto.status,
          moderatedAt: now,
          moderationReason: dto.reason ?? null,
          moderatedById: moderator.userId,
        },
      });

      if (dto.status === 'APPROVED') {
        await this.reportApprovalPoints.creditApprovalIfEligible(tx, {
          report: {
            id: updatedReport.id,
            reporterId: updatedReport.reporterId,
            siteId: updatedReport.siteId,
            mediaUrls: updatedReport.mediaUrls,
            severity: updatedReport.severity,
            cleanupEffort: updatedReport.cleanupEffort,
          },
          now,
        });
      }

      if (dto.status === 'DELETED' && report.status === 'APPROVED' && report.reporterId) {
        await this.reportApprovalPoints.debitRevokedApprovalIfNeeded(tx, {
          reportId,
          userId: report.reporterId,
        });
      }

      let siteStatusEvent: {
        id: string;
        status: SiteStatus;
        latitude: number;
        longitude: number;
        updatedAt: Date;
      } | null = null;
      if (dto.status === 'APPROVED') {
        const otherApprovedCount = await tx.report.count({
          where: {
            siteId: updatedReport.siteId,
            status: 'APPROVED',
            id: { not: reportId },
          },
        });
        if (otherApprovedCount === 0) {
          siteStatusEvent = await transitionSiteToVerifiedIfFirstApproved(tx, updatedReport.siteId);
        }
      }

      const coReporterUserIds = report.coReporters.map((c) => c.userId);
      const moderationPayload: ModerationStatusSideEffectPayload = {
        moderatorUserId: moderator.userId,
        reportId,
        fromStatus: report.status,
        toStatus: dto.status,
        reason: dto.reason ?? null,
        siteId: updatedReport.siteId,
        reporterId: report.reporterId,
        coReporterUserIds,
        siteStatusEvent:
          siteStatusEvent == null
            ? null
            : {
                id: siteStatusEvent.id,
                status: siteStatusEvent.status,
                latitude: siteStatusEvent.latitude,
                longitude: siteStatusEvent.longitude,
                updatedAt: siteStatusEvent.updatedAt.toISOString(),
              },
      };

      const effect = await tx.reportSideEffect.create({
        data: {
          kind: ReportSideEffectKind.MODERATION_STATUS_POST,
          status: ReportSideEffectStatus.PENDING,
          payload: moderationPayload as object,
        },
      });

      return { updatedReport, siteStatusEvent, effectId: effect.id };
    });
    const updated = updatedResult.updatedReport;
    await this.reportSideEffectProcessor.processModerationStatusPost(updatedResult.effectId);
    return updated;
  }

  async findOneForModeration(reportId: string): Promise<AdminReportDetailDto> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        createdAt: true,
        reportNumber: true,
        status: true,
        title: true,
        description: true,
        category: true,
        moderatedAt: true,
        moderationReason: true,
        mediaUrls: true,
        cleanupEffort: true,
        potentialDuplicateOfId: true,
        reporterId: true,
        site: {
          select: {
            latitude: true,
            longitude: true,
            description: true,
            address: true,
          },
        },
        reporter: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        moderatedBy: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        coReporters: {
          select: {
            userId: true,
            user: {
              select: {
                firstName: true,
                lastName: true,
              },
            },
          },
        },
        potentialDuplicateOf: {
          select: {
            id: true,
            createdAt: true,
            reportNumber: true,
          },
        },
        potentialDuplicates: {
          select: {
            id: true,
          },
        },
      },
    });

    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    const reportNumber = getReportNumber(report);
    const locationLabel = listLocationLabel(report.site, report.description);

    const reporterAlias = report.reporter
      ? `${report.reporter.firstName} ${report.reporter.lastName}`.trim()
      : 'Anonymous reporter';

    const {
      moderationQueueLabel,
      moderationAssignedTeam,
      moderationSlaLabel,
    } = moderationQueueMetaForStatus(report.status);

    const signedMediaUrls = await this.reportsUploadService.signUrls(report.mediaUrls ?? []);
    const evidence = signedMediaUrls.map((url, index) => ({
      id: `ev-${index + 1}`,
      label: `Evidence ${index + 1}`,
      kind: 'image' as const,
      sizeLabel: '—',
      uploadedAt: report.createdAt.toISOString(),
      previewUrl: url,
      previewAlt: `Evidence ${index + 1} for report ${reportNumber}`,
    }));

    const timeline = [
      {
        id: 'tl-submitted',
        title: 'Report submitted',
        detail: 'Initial report created with location and optional media evidence.',
        actor: reporterAlias,
        occurredAt: report.createdAt.toISOString(),
        tone: 'info' as const,
      },
      ...(report.moderatedAt
        ? [
            {
              id: 'tl-moderated',
              title:
                report.status === 'APPROVED'
                  ? 'Report approved'
                  : report.status === 'DELETED'
                    ? 'Report rejected'
                    : 'Report updated',
              detail:
                report.moderationReason ??
                (report.status === 'APPROVED'
                  ? 'Report was approved after moderation review.'
                  : 'Report was updated during moderation review.'),
              actor: report.moderatedBy
                ? `${report.moderatedBy.firstName} ${report.moderatedBy.lastName}`.trim()
                : 'Moderator',
              occurredAt: report.moderatedAt.toISOString(),
              tone:
                report.status === 'APPROVED'
                  ? ('success' as const)
                  : report.status === 'DELETED'
                    ? ('warning' as const)
                    : ('neutral' as const),
            },
          ]
        : []),
    ];

    const coReporters: string[] = report.coReporters
      .map((coReporter) =>
        coReporter.user
          ? `${coReporter.user.firstName} ${coReporter.user.lastName}`.trim()
          : null,
      )
      .filter((alias): alias is string => !!alias);

    const isPotentialDuplicate =
      report.potentialDuplicateOfId !== null || report.potentialDuplicates.length > 0 || coReporters.length > 0;

    const potentialDuplicateOfReportNumber = report.potentialDuplicateOf
      ? getReportNumber(report.potentialDuplicateOf)
      : null;

    return {
      id: report.id,
      reportNumber,
      status: report.status,
      priority: deriveAdminReportDetailPriority(report.status),
      title: displayReportTitle(report),
      description: optionalReportNarrative(report.description, report.category) ?? '',
      location: locationLabel,
      submittedAt: report.createdAt.toISOString(),
      reporterAlias,
      reporterTrust: 'Bronze',
      evidence,
      timeline,
      moderation: {
        queueLabel: moderationQueueLabel,
        slaLabel: moderationSlaLabel,
        assignedTeam: moderationAssignedTeam,
      },
      mapPin: {
        latitude: report.site.latitude,
        longitude: report.site.longitude,
        label: locationLabel,
      },
      isPotentialDuplicate,
      coReporters,
      potentialDuplicateOfReportNumber,
      cleanupEffortLabel: reportCleanupEffortLabel(report.cleanupEffort),
    };
  }
}
