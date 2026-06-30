import { Injectable } from '@nestjs/common';
import { Prisma, SiteResolutionStatus } from '../../../prisma-client';
import { EcoEventPointsService, type EcoEventPointsCreditResult } from '../../../gamification/services/eco-event-points.service';
import {
  DAILY_SITE_RESOLUTION_POINTS_CAP,
  REASON_SITE_RESOLUTION_APPROVAL_REVOKED,
  REASON_SITE_RESOLUTION_APPROVED,
  SITE_RESOLUTION_MAX_REWARDED_CONTRIBUTORS,
  SITE_RESOLUTION_POINTS_BASE,
  SITE_RESOLUTION_POINTS_MEDIA_PER_PHOTO,
  SITE_RESOLUTION_POINTS_MEDIA_PER_PHOTO_MAX,
  SITE_RESOLUTION_POINTS_METADATA_VERSION,
  SITE_RESOLUTION_POINTS_PIONEER,
} from '../../../gamification/constants/gamification.constants';
import { getSkopjeDayBoundsUtc } from '../../../gamification/util/week-skopje';

export type SiteResolutionPointsInput = {
  id: string;
  siteId: string;
  submittedById: string | null;
  isReporterSubmission: boolean;
  mediaUrls: string[];
};

@Injectable()
export class SiteResolutionPointsService {
  constructor(private readonly ecoEventPoints: EcoEventPointsService) {}

  computePoints(input: SiteResolutionPointsInput, priorRewardedNonReporterCount: number): {
    preCapTotal: number;
    breakdown: Array<{ code: string; points: number }>;
    pioneer: boolean;
  } {
    if (input.isReporterSubmission || input.submittedById == null) {
      return { preCapTotal: 0, breakdown: [], pioneer: false };
    }
    if (priorRewardedNonReporterCount >= SITE_RESOLUTION_MAX_REWARDED_CONTRIBUTORS) {
      return { preCapTotal: 0, breakdown: [], pioneer: false };
    }

    const breakdown: Array<{ code: string; points: number }> = [];
    let total = SITE_RESOLUTION_POINTS_BASE;
    breakdown.push({ code: 'SITE_RESOLUTION_BASE', points: SITE_RESOLUTION_POINTS_BASE });

    const mediaCount = Math.min(
      SITE_RESOLUTION_POINTS_MEDIA_PER_PHOTO_MAX,
      Math.max(0, input.mediaUrls.length),
    );
    const mediaPts = mediaCount * SITE_RESOLUTION_POINTS_MEDIA_PER_PHOTO;
    if (mediaPts > 0) {
      breakdown.push({ code: 'SITE_RESOLUTION_MEDIA', points: mediaPts });
      total += mediaPts;
    }

    const pioneer = priorRewardedNonReporterCount === 0;
    if (pioneer) {
      breakdown.push({ code: 'SITE_RESOLUTION_PIONEER', points: SITE_RESOLUTION_POINTS_PIONEER });
      total += SITE_RESOLUTION_POINTS_PIONEER;
    }

    return { preCapTotal: total, breakdown, pioneer };
  }

  async countPriorRewardedNonReporterContributors(
    tx: Prisma.TransactionClient,
    siteId: string,
    excludeResolutionId: string,
  ): Promise<number> {
    const rows = await tx.siteResolution.findMany({
      where: {
        siteId,
        status: SiteResolutionStatus.APPROVED,
        isReporterSubmission: false,
        submittedById: { not: null },
        id: { not: excludeResolutionId },
      },
      select: { submittedById: true },
      distinct: ['submittedById'],
    });
    return rows.length;
  }

  async creditApprovalIfEligible(
    tx: Prisma.TransactionClient,
    params: { resolution: SiteResolutionPointsInput; now: Date },
  ): Promise<{ awarded: number; credit: EcoEventPointsCreditResult }> {
    const { resolution, now } = params;
    if (resolution.submittedById == null || resolution.isReporterSubmission) {
      return {
        awarded: 0,
        credit: { granted: 0, totalPointsEarnedBefore: 0, totalPointsEarnedAfter: 0 },
      };
    }

    const priorCount = await this.countPriorRewardedNonReporterContributors(
      tx,
      resolution.siteId,
      resolution.id,
    );
    const { preCapTotal, breakdown } = this.computePoints(resolution, priorCount);
    if (preCapTotal <= 0) {
      return {
        awarded: 0,
        credit: { granted: 0, totalPointsEarnedBefore: 0, totalPointsEarnedAfter: 0 },
      };
    }

    const { dayStartsAt, dayEndsAt } = getSkopjeDayBoundsUtc(now);
    const earnedTodayAgg = await tx.pointTransaction.aggregate({
      where: {
        userId: resolution.submittedById,
        reasonCode: REASON_SITE_RESOLUTION_APPROVED,
        delta: { gt: 0 },
        createdAt: { gte: dayStartsAt, lte: dayEndsAt },
      },
      _sum: { delta: true },
    });
    const earnedTodayBefore = earnedTodayAgg._sum.delta ?? 0;
    const room = Math.max(0, DAILY_SITE_RESOLUTION_POINTS_CAP - earnedTodayBefore);
    const award = Math.min(preCapTotal, room);

    if (award <= 0) {
      return {
        awarded: 0,
        credit: { granted: 0, totalPointsEarnedBefore: 0, totalPointsEarnedAfter: 0 },
      };
    }

    const metadata: Prisma.InputJsonValue = {
      version: SITE_RESOLUTION_POINTS_METADATA_VERSION,
      breakdown,
      ...(award < preCapTotal
        ? {
            capsApplied: {
              preCapTotal,
              earnedTodayBefore,
              cap: DAILY_SITE_RESOLUTION_POINTS_CAP,
            },
          }
        : {}),
    };

    const credit = await this.ecoEventPoints.creditIfNew(tx, {
      userId: resolution.submittedById,
      delta: award,
      reasonCode: REASON_SITE_RESOLUTION_APPROVED,
      referenceType: 'SiteResolution',
      referenceId: resolution.id,
      metadata,
    });

    return { awarded: credit.granted, credit };
  }

  async debitRevokedApprovalIfNeeded(
    tx: Prisma.TransactionClient,
    params: { resolutionId: string; userId: string | null },
  ): Promise<number> {
    const { resolutionId, userId } = params;
    if (userId == null) {
      return 0;
    }
    const sumAgg = await tx.pointTransaction.aggregate({
      where: {
        userId,
        referenceType: 'SiteResolution',
        referenceId: resolutionId,
        delta: { gt: 0 },
      },
      _sum: { delta: true },
    });
    const positiveSum = sumAgg._sum.delta ?? 0;
    if (positiveSum <= 0) {
      return 0;
    }
    return this.ecoEventPoints.debitOnceIfNew(tx, {
      userId,
      delta: -positiveSum,
      reasonCode: REASON_SITE_RESOLUTION_APPROVAL_REVOKED,
      referenceType: 'SiteResolution',
      referenceId: resolutionId,
    });
  }
}
