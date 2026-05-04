import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Prisma, ReportSideEffectKind, ReportSideEffectStatus, SiteStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  MergeDuplicateReportsDto,
  MergeDuplicateReportsResponseDto,
} from './dto/admin-duplicate-report.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { DuplicateGroupQueryService } from './duplicates/duplicate-group-query.service';
import { ReportSideEffectProcessorService } from './side-effects/report-side-effect-processor.service';
import type { MergeDuplicateSideEffectPayload } from './side-effects/report-side-effect-processor.service';
import { transitionSiteToVerifiedIfFirstApproved } from './report-site-verification.helper';
import { ReportApprovalPointsService } from './report-approval-points.service';

@Injectable()
export class ReportsDuplicateMergeService {
  private readonly logger = new Logger(ReportsDuplicateMergeService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly duplicateGroupQuery: DuplicateGroupQueryService,
    private readonly reportApprovalPoints: ReportApprovalPointsService,
    private readonly reportSideEffectProcessor: ReportSideEffectProcessorService,
  ) {}

  findDuplicateGroups(query: ListReportsQueryDto): Promise<AdminDuplicateReportGroupsResponseDto> {
    return this.duplicateGroupQuery.findDuplicateGroups(query);
  }

  findDuplicateGroupByReport(reportId: string): Promise<AdminDuplicateReportGroupDto> {
    return this.duplicateGroupQuery.findDuplicateGroupByReport(reportId);
  }

  private async buildMergeCompletedSnapshot(
    primaryReportId: string,
    metrics: {
      mergedChildCount: number;
      mergedMediaCount: number;
      mergedCoReporterCount: number;
    },
  ): Promise<MergeDuplicateReportsResponseDto> {
    const primaryAfter = await this.prisma.report.findUniqueOrThrow({
      where: { id: primaryReportId },
      select: {
        status: true,
        reporterId: true,
        coReporters: {
          select: {
            userId: true,
            reportedAt: true,
            user: {
              select: {
                firstName: true,
                lastName: true,
              },
            },
          },
          orderBy: { reportedAt: 'asc' },
        },
      },
    });

    const coReporters = primaryAfter.coReporters.map((row) => ({
      userId: row.userId,
      name: `${row.user.firstName} ${row.user.lastName}`.trim(),
      reportedAt: row.reportedAt.toISOString(),
    }));

    const reporterCount = (primaryAfter.reporterId ? 1 : 0) + primaryAfter.coReporters.length;

    return {
      primaryReportId,
      mergedChildCount: metrics.mergedChildCount,
      mergedMediaCount: metrics.mergedMediaCount,
      mergedCoReporterCount: metrics.mergedCoReporterCount,
      primaryStatus: primaryAfter.status,
      coReporters,
      reporterCount,
    };
  }

  async mergeDuplicateReports(
    reportId: string,
    dto: MergeDuplicateReportsDto,
    moderator: AuthenticatedUser,
  ): Promise<MergeDuplicateReportsResponseDto> {
    const primaryReportId = await this.duplicateGroupQuery.findPrimaryReportId(reportId);
    const now = new Date();

    const primaryReport = await this.prisma.report.findUnique({
      where: { id: primaryReportId },
      select: {
        id: true,
        siteId: true,
        status: true,
        reporterId: true,
        reportNumber: true,
        createdAt: true,
        mediaUrls: true,
        severity: true,
        cleanupEffort: true,
        coReporters: {
          select: {
            userId: true,
          },
        },
        potentialDuplicates: {
          select: {
            id: true,
            reporterId: true,
            createdAt: true,
            mediaUrls: true,
            coReporters: {
              select: {
                userId: true,
                createdAt: true,
              },
            },
          },
        },
      },
    });

    if (!primaryReport) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    if (primaryReport.status === 'DELETED') {
      throw new BadRequestException({
        code: 'PRIMARY_REPORT_NOT_MERGEABLE',
        message: `Primary report '${primaryReportId}' is deleted and cannot be used as a merge target`,
      });
    }

    const childIdsInGroup = new Set(primaryReport.potentialDuplicates.map((child) => child.id));
    const selectedChildIds = [...new Set(dto.childReportIds)];
    const invalidChildIds = selectedChildIds.filter((childId) => !childIdsInGroup.has(childId));

    if (invalidChildIds.length > 0) {
      if (invalidChildIds.length !== selectedChildIds.length) {
        throw new BadRequestException({
          code: 'INVALID_DUPLICATE_SELECTION',
          message: 'One or more selected child reports do not belong to the duplicate group',
          details: {
            invalidChildIds,
          },
        });
      }
      const orphanCount = await this.prisma.report.count({
        where: { id: { in: selectedChildIds } },
      });
      if (orphanCount > 0) {
        throw new BadRequestException({
          code: 'INVALID_DUPLICATE_SELECTION',
          message: 'One or more selected child reports do not belong to the duplicate group',
          details: {
            invalidChildIds,
          },
        });
      }
      return this.buildMergeCompletedSnapshot(primaryReport.id, {
        mergedChildCount: 0,
        mergedMediaCount: 0,
        mergedCoReporterCount: 0,
      });
    }

    const selectedChildren = primaryReport.potentialDuplicates.filter((child) =>
      selectedChildIds.includes(child.id),
    );
    if (selectedChildren.length === 0) {
      throw new BadRequestException({
        code: 'EMPTY_MERGE_SELECTION',
        message: 'At least one duplicate child report must be selected for merge',
      });
    }

    const duplicateMediaUrls = [...new Set(selectedChildren.flatMap((child) => child.mediaUrls))];

    const currentCoReporterIds = new Set(primaryReport.coReporters.map((coReporter) => coReporter.userId));
    const coReporterReportedAt = new Map<string, Date>();
    const primaryReporterId = primaryReport.reporterId;

    const offerCoReporter = (userId: string | null | undefined, reportedAt: Date) => {
      if (!userId || userId === primaryReporterId) {
        return;
      }
      const prev = coReporterReportedAt.get(userId);
      if (!prev || reportedAt < prev) {
        coReporterReportedAt.set(userId, reportedAt);
      }
    };

    for (const child of selectedChildren) {
      offerCoReporter(child.reporterId, child.createdAt);
      for (const coReporter of child.coReporters) {
        offerCoReporter(coReporter.userId, coReporter.createdAt);
      }
    }

    const plannedNewCoReporterIds = [...coReporterReportedAt.keys()].filter(
      (userId) => !currentCoReporterIds.has(userId),
    );

    const mergeTxResult = await this.prisma.$transaction(async (tx) => {
      let siteStatusEvent: {
        id: string;
        status: SiteStatus;
        latitude: number;
        longitude: number;
        updatedAt: Date;
      } | null = null;

      await tx.report.updateMany({
        where: { potentialDuplicateOfId: { in: selectedChildIds } },
        data: { potentialDuplicateOfId: primaryReport.id },
      });

      for (const userId of plannedNewCoReporterIds) {
        const reportedAt = coReporterReportedAt.get(userId);
        if (!reportedAt) {
          continue;
        }
        await tx.reportCoReporter.upsert({
          where: {
            reportId_userId: {
              reportId: primaryReport.id,
              userId,
            },
          },
          update: {},
          create: {
            reportId: primaryReport.id,
            userId,
            reportedAt,
          },
        });
      }

      const primaryUpdate: Prisma.ReportUncheckedUpdateInput = {
        potentialDuplicateOfId: null,
        mergedDuplicateChildCount: { increment: selectedChildren.length },
      };
      if (primaryReport.status !== 'APPROVED') {
        primaryUpdate.status = 'APPROVED';
        primaryUpdate.moderatedAt = now;
        primaryUpdate.moderatedById = moderator.userId;
        primaryUpdate.moderationReason = dto.reason ?? 'Merged duplicate';
      }

      await tx.report.update({
        where: { id: primaryReport.id },
        data: primaryUpdate,
      });

      if (primaryReport.status !== 'APPROVED') {
        const updatedPrimary = await tx.report.findUniqueOrThrow({
          where: { id: primaryReport.id },
          select: {
            id: true,
            reporterId: true,
            siteId: true,
            mediaUrls: true,
            severity: true,
            cleanupEffort: true,
          },
        });
        await this.reportApprovalPoints.creditApprovalIfEligible(tx, {
          report: updatedPrimary,
          now,
        });
      }

      const approvedCountForSite = await tx.report.count({
        where: {
          siteId: primaryReport.siteId,
          status: 'APPROVED',
        },
      });
      if (approvedCountForSite === 1) {
        siteStatusEvent = await transitionSiteToVerifiedIfFirstApproved(tx, primaryReport.siteId);
      }

      await tx.report.deleteMany({
        where: { id: { in: selectedChildIds } },
      });

      const mergePayload: MergeDuplicateSideEffectPayload = {
        moderator,
        primaryReport: {
          id: primaryReport.id,
          siteId: primaryReport.siteId,
          reporterId: primaryReport.reporterId,
          reportNumber: primaryReport.reportNumber,
          createdAt: primaryReport.createdAt.toISOString(),
          mediaUrls: primaryReport.mediaUrls,
        },
        selectedChildIds,
        selectedChildren: selectedChildren.map((c) => ({
          id: c.id,
          reporterId: c.reporterId,
        })),
        plannedNewCoReporterIds,
        duplicateMediaUrls,
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
          kind: ReportSideEffectKind.MERGE_DUPLICATE_POST,
          status: ReportSideEffectStatus.PENDING,
          payload: mergePayload as object,
        },
      });

      return { siteStatusEvent, effectId: effect.id };
    });

    let mergedMediaDeletedCount = 0;
    try {
      mergedMediaDeletedCount = await this.reportSideEffectProcessor.processMergeDuplicatePost(
        mergeTxResult.effectId,
      );
    } catch (err) {
      this.logger.error(
        `Merge duplicate post-effects processor threw (effectId=${mergeTxResult.effectId})`,
        err,
      );
    }

    return this.buildMergeCompletedSnapshot(primaryReport.id, {
      mergedChildCount: selectedChildren.length,
      mergedMediaCount: mergedMediaDeletedCount,
      mergedCoReporterCount: plannedNewCoReporterIds.length,
    });
  }
}
