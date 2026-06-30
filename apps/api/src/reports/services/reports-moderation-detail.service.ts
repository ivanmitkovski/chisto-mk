import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminReportDetailDto } from '../dto/admin-report.dto';
import { ReportsUploadService } from './reports-upload.service';
import { reportCleanupEffortLabel } from '../util/report-cleanup-effort';
import {
  displayReportTitle,
  getReportNumber,
  listLocationLabel,
  optionalReportNarrative,
} from '../util/report-copy.helpers';
import { deriveAdminReportDetailPriority } from '../util/report-moderation-priority.helper';
import { moderationQueueMetaForStatus } from '../util/report-moderation-queue-meta';
import { resolveActorIdentity } from '../../common/projections/public-identity.projection';

@Injectable()
export class ReportsModerationDetailService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

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
            status: true,
          },
        },
        moderatedBy: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            status: true,
          },
        },
        moderatedById: true,
        coReporters: {
          select: {
            userId: true,
            user: {
              select: {
                firstName: true,
                lastName: true,
                status: true,
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

    const reporterIdentity = resolveActorIdentity(report.reporter, {
      actorUserId: report.reporterId,
    });
    const reporterAlias = reporterIdentity.isDeleted
      ? 'Deleted user'
      : (reporterIdentity.displayName ?? 'Anonymous reporter');

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
                ? (resolveActorIdentity(report.moderatedBy, {
                    actorUserId: report.moderatedBy.id,
                  }).displayName ?? 'Moderator')
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
      .map((coReporter) => {
        const identity = resolveActorIdentity(coReporter.user, {
          actorUserId: coReporter.userId,
        });
        return identity.isDeleted ? null : identity.displayName;
      })
      .filter((alias): alias is string => alias != null && alias.length > 0);

    const isPotentialDuplicate =
      report.potentialDuplicateOfId !== null || report.potentialDuplicates.length > 0 || coReporters.length > 0;

    const potentialDuplicateOfReportNumber = report.potentialDuplicateOf
      ? getReportNumber(report.potentialDuplicateOf)
      : null;

    const assignedModerator =
      report.moderatedById && (report.status === 'NEW' || report.status === 'IN_REVIEW')
        ? {
            id: report.moderatedById,
            name: report.moderatedBy
              ? (resolveActorIdentity(report.moderatedBy, {
                  actorUserId: report.moderatedBy.id,
                }).displayName ?? 'Moderator')
              : 'Moderator',
          }
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
        assignedTeam: assignedModerator?.name ?? moderationAssignedTeam,
        assignedModeratorId: assignedModerator?.id ?? null,
        assignedModeratorName: assignedModerator?.name ?? null,
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
