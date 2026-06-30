import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Prisma, ReportSideEffectKind, ReportSideEffectStatus, SiteStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { MergeDuplicateReportsDto, MergeDuplicateReportsResponseDto } from '../dto/admin-duplicate-report.dto';
import { DuplicateGroupQueryService } from '../duplicates/duplicate-group-query.service';
import { ReportSideEffectProcessorService } from '../side-effects/report-side-effect-processor.service';
import { buildMergeSideEffectPayload, planMergedCoReporters } from '../util/duplicate-merge-plan.util';
import { transitionSiteToVerifiedIfFirstApproved } from '../util/report-site-verification.helper';
import { ReportApprovalPointsService } from './report-approval-points.service';
import { DuplicateMergeSnapshotService } from './duplicate-merge-snapshot.service';
import { SiteHeroImageService } from '../../sites/services/site-hero-image.service';
import { emitGamificationPointsCredited } from '../../gamification/util/gamification-credit-events.util';
import type { EcoEventPointsCreditResult } from '../../gamification/services/eco-event-points.service';

@Injectable()
export class DuplicateMergeTransactionService {
  private readonly logger = new Logger(DuplicateMergeTransactionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly duplicateGroupQuery: DuplicateGroupQueryService,
    private readonly reportApprovalPoints: ReportApprovalPointsService,
    private readonly reportSideEffectProcessor: ReportSideEffectProcessorService,
    private readonly snapshot: DuplicateMergeSnapshotService,
    private readonly siteHeroImage: SiteHeroImageService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

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
      return this.snapshot.buildMergeCompletedSnapshot(primaryReport.id, {
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

    const { plannedNewCoReporterIds, coReporterReportedAt } = planMergedCoReporters(
      primaryReport,
      selectedChildren,
    );

    const mergeTxResult = await this.prisma.$transaction(async (tx) => {
      let siteStatusEvent: {
        id: string;
        status: SiteStatus;
        latitude: number;
        longitude: number;
        updatedAt: Date;
      } | null = null;
      let approvalCredit: { userId: string; credit: EcoEventPointsCreditResult } | null = null;

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
        const pointsResult = await this.reportApprovalPoints.creditApprovalIfEligible(tx, {
          report: updatedPrimary,
          now,
        });
        if (updatedPrimary.reporterId != null && pointsResult.credit.granted > 0) {
          approvalCredit = {
            userId: updatedPrimary.reporterId,
            credit: pointsResult.credit,
          };
        }
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

      const heroResult = await this.siteHeroImage.recomputeSiteHero(tx, primaryReport.siteId);

      const mergePayload = buildMergeSideEffectPayload({
        moderator,
        primaryReport,
        selectedChildIds,
        selectedChildren,
        plannedNewCoReporterIds,
        duplicateMediaUrls,
        siteStatusEvent,
      });

      const effect = await tx.reportSideEffect.create({
        data: {
          kind: ReportSideEffectKind.MERGE_DUPLICATE_POST,
          status: ReportSideEffectStatus.PENDING,
          payload: mergePayload as object,
        },
      });

      return { siteStatusEvent, effectId: effect.id, heroResult, approvalCredit };
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

    if (mergeTxResult.approvalCredit != null) {
      emitGamificationPointsCredited(
        this.eventEmitter,
        mergeTxResult.approvalCredit.userId,
        mergeTxResult.approvalCredit.credit,
      );
    }

    if (mergeTxResult.heroResult.changed) {
      this.siteHeroImage.emitIfChanged(primaryReport.siteId, mergeTxResult.heroResult);
    }

    return this.snapshot.buildMergeCompletedSnapshot(primaryReport.id, {
      mergedChildCount: selectedChildren.length,
      mergedMediaCount: mergedMediaDeletedCount,
      mergedCoReporterCount: plannedNewCoReporterIds.length,
    });
  }
}
