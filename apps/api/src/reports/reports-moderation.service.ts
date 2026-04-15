import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Prisma, Report, ReportStatus, SiteStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  AdminReportDetailDto,
  AdminReportListItemDto,
  AdminReportListResponseDto,
} from './dto/admin-report.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { ReportsUploadService } from './reports-upload.service';
import { ReportEventsService } from '../admin-events/report-events.service';
import { SiteEventsService } from '../admin-events/site-events.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import { reportCleanupEffortLabel } from './report-cleanup-effort';
import { POINTS_FIRST_REPORT } from '../gamification/gamification.constants';
import {
  displayReportTitle,
  getReportNumber,
  listLocationLabel,
  optionalReportNarrative,
} from './report-copy.helpers';
import { transitionSiteToVerifiedIfFirstApproved } from './report-site-verification.helper';

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
    private readonly audit: AuditService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly reportEventsService: ReportEventsService,
    private readonly siteEventsService: SiteEventsService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  private derivePriority(status: ReportStatus): AdminReportDetailDto['priority'] {
    if (status === 'NEW') {
      return 'HIGH';
    }

    if (status === 'IN_REVIEW') {
      return 'MEDIUM';
    }

    if (status === 'APPROVED') {
      return 'LOW';
    }

    return 'LOW';
  }

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
        include: {
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
          coReporters: true,
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
      select: { id: true, status: true, reporterId: true },
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

      if (dto.status === 'APPROVED' && updatedReport.reporterId) {
        const existingAward = await tx.pointTransaction.findFirst({
          where: {
            referenceType: 'Report',
            referenceId: reportId,
          },
        });
        if (!existingAward) {
          const otherApprovedCount = await tx.report.count({
            where: {
              siteId: updatedReport.siteId,
              status: 'APPROVED',
              id: { not: reportId },
            },
          });
          const isFirstApproved = otherApprovedCount === 0;
          if (isFirstApproved) {
            const points = POINTS_FIRST_REPORT;
            const user = await tx.user.findUnique({
              where: { id: updatedReport.reporterId },
              select: { pointsBalance: true, totalPointsEarned: true },
            });
            if (user) {
              const balanceAfter = user.pointsBalance + points;
              const totalEarnedAfter = user.totalPointsEarned + points;
              await tx.pointTransaction.create({
                data: {
                  userId: updatedReport.reporterId,
                  delta: points,
                  balanceAfter,
                  reasonCode: 'FIRST_REPORT',
                  referenceType: 'Report',
                  referenceId: reportId,
                },
              });
              await tx.user.update({
                where: { id: updatedReport.reporterId },
                data: {
                  pointsBalance: balanceAfter,
                  totalPointsEarned: totalEarnedAfter,
                },
              });
            }
          }
        }
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

      return { updatedReport, siteStatusEvent };
    });
    const updated = updatedResult.updatedReport;
    if (updatedResult.siteStatusEvent != null) {
      const siteStatusEvent = updatedResult.siteStatusEvent;
      this.siteEventsService.emitSiteUpdated(siteStatusEvent.id, {
        kind: 'status_changed',
        status: siteStatusEvent.status,
        latitude: siteStatusEvent.latitude,
        longitude: siteStatusEvent.longitude,
        updatedAt: siteStatusEvent.updatedAt,
      });
    }

    await this.audit.log({
      actorId: moderator.userId,
      action: 'REPORT_STATUS_UPDATED',
      resourceType: 'Report',
      resourceId: reportId,
      metadata: { from: report.status, to: dto.status },
    });

    this.reportEventsService.emitReportStatusUpdated(reportId);
    if (report.reporterId) {
      this.reportsOwnerEventsService.emit(
        report.reporterId,
        reportId,
        'report_updated',
        { kind: 'status_changed', status: dto.status },
      );
      const statusLabel = dto.status.toLowerCase().replace(/_/g, ' ');
      this.eventEmitter.emit('notification.send', {
        recipientUserIds: [report.reporterId],
        title: 'Report status updated',
        body: `Your report has been ${statusLabel}`,
        type: 'REPORT_STATUS',
        threadKey: `report:${reportId}`,
        groupKey: `REPORT_STATUS:site:${updated.siteId}`,
        data: { reportId, siteId: updated.siteId, status: dto.status },
      });
    }
    return updated;
  }

  async findOneForModeration(reportId: string): Promise<AdminReportDetailDto> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      include: {
        site: true,
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
          include: {
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

    const moderationQueueLabel = 'General Queue';
    const moderationAssignedTeam = 'City Moderation';
    const moderationSlaLabel =
      report.status === 'NEW' ? '4h remaining' : report.status === 'IN_REVIEW' ? '2h remaining' : 'Completed';

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
      priority: this.derivePriority(report.status),
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
