import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AdminReportDetailDto } from './dto/admin-report.dto';
import { ReportsUploadService } from './reports-upload.service';
import { reportCleanupEffortLabel } from './report-cleanup-effort';
import {
  displayReportTitle,
  getReportNumber,
  listLocationLabel,
  optionalReportNarrative,
} from './report-copy.helpers';
import { deriveAdminReportDetailPriority } from './report-moderation-priority.helper';
import { moderationQueueMetaForStatus } from './report-moderation-queue-meta';

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
