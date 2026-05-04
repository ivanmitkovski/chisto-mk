import { Injectable } from '@nestjs/common';
import { Prisma, ReportCleanupEffort } from '../prisma-client';
import { EcoEventPointsService } from '../gamification/eco-event-points.service';
import {
  DAILY_REPORT_APPROVAL_POINTS_CAP,
  REPORT_APPROVAL_POINTS_METADATA_VERSION,
  REASON_REPORT_APPROVAL_REVOKED,
  REASON_REPORT_APPROVED,
} from '../gamification/gamification.constants';
import { getSkopjeDayBoundsUtc } from '../gamification/week-skopje';
import { ObservabilityStore } from '../observability/observability.store';
import { ReportPointsService } from './report-points.service';

export type ReportApprovalGrantReportShape = {
  id: string;
  reporterId: string | null;
  siteId: string;
  mediaUrls: string[];
  severity: number | null;
  cleanupEffort: ReportCleanupEffort | null;
};

@Injectable()
export class ReportApprovalPointsService {
  constructor(
    private readonly reportPoints: ReportPointsService,
    private readonly ecoEventPoints: EcoEventPointsService,
  ) {}

  /**
   * Idempotent approval grant inside an interactive transaction (report row must already be APPROVED).
   */
  async creditApprovalIfEligible(
    tx: Prisma.TransactionClient,
    params: { report: ReportApprovalGrantReportShape; now: Date },
  ): Promise<{ awarded: number; preCapTotal: number }> {
    const { report, now } = params;
    if (report.reporterId == null) {
      return { awarded: 0, preCapTotal: 0 };
    }

    const otherApproved = await tx.report.count({
      where: { siteId: report.siteId, status: 'APPROVED', id: { not: report.id } },
    });

    const { preCapTotal, breakdown } = this.reportPoints.computeApprovalPoints({
      mediaCount: report.mediaUrls.length,
      severity: report.severity,
      cleanupEffort: report.cleanupEffort,
      otherApprovedReportCountOnSite: otherApproved,
    });

    if (preCapTotal <= 0) {
      return { awarded: 0, preCapTotal: 0 };
    }

    const { dayStartsAt, dayEndsAt } = getSkopjeDayBoundsUtc(now);
    const earnedTodayAgg = await tx.pointTransaction.aggregate({
      where: {
        userId: report.reporterId,
        reasonCode: REASON_REPORT_APPROVED,
        delta: { gt: 0 },
        createdAt: { gte: dayStartsAt, lte: dayEndsAt },
      },
      _sum: { delta: true },
    });
    const earnedTodayBefore = earnedTodayAgg._sum.delta ?? 0;
    const room = Math.max(0, DAILY_REPORT_APPROVAL_POINTS_CAP - earnedTodayBefore);
    const award = Math.min(preCapTotal, room);

    if (award < preCapTotal) {
      ObservabilityStore.recordReportApprovalPointsCapped();
    }

    if (award <= 0) {
      return { awarded: 0, preCapTotal };
    }

    const metadata: Prisma.InputJsonValue = {
      version: REPORT_APPROVAL_POINTS_METADATA_VERSION,
      breakdown,
      ...(award < preCapTotal
        ? {
            capsApplied: {
              preCapTotal,
              earnedTodayBefore,
              cap: DAILY_REPORT_APPROVAL_POINTS_CAP,
            },
          }
        : {}),
    };

    const granted = await this.ecoEventPoints.creditIfNew(tx, {
      userId: report.reporterId,
      delta: award,
      reasonCode: REASON_REPORT_APPROVED,
      referenceType: 'Report',
      referenceId: report.id,
      metadata,
    });
    if (granted > 0) {
      ObservabilityStore.recordReportApprovalPointsAwarded(granted);
    }
    return { awarded: granted, preCapTotal };
  }

  /**
   * Reverses all positive report-scoped points for this user/report (legacy rows included), once.
   */
  async debitRevokedApprovalIfNeeded(
    tx: Prisma.TransactionClient,
    params: { reportId: string; userId: string | null },
  ): Promise<number> {
    const { reportId, userId } = params;
    if (userId == null) {
      return 0;
    }
    const sumAgg = await tx.pointTransaction.aggregate({
      where: {
        userId,
        referenceType: 'Report',
        referenceId: reportId,
        delta: { gt: 0 },
      },
      _sum: { delta: true },
    });
    const positiveSum = sumAgg._sum.delta ?? 0;
    if (positiveSum <= 0) {
      return 0;
    }
    const applied = await this.ecoEventPoints.debitOnceIfNew(tx, {
      userId,
      delta: -positiveSum,
      reasonCode: REASON_REPORT_APPROVAL_REVOKED,
      referenceType: 'Report',
      referenceId: reportId,
    });
    if (applied !== 0) {
      ObservabilityStore.recordReportApprovalPointsRevoked(Math.abs(applied));
    }
    return applied;
  }
}
