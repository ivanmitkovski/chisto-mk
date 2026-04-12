import { Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';

export type EcoEventPointsCreditParams = {
  userId: string;
  delta: number;
  reasonCode: string;
  referenceType: string;
  referenceId: string;
};

export type EcoEventPointsDebitParams = {
  userId: string;
  /** Must be negative. */
  delta: number;
  reasonCode: string;
  referenceType: string;
  referenceId: string;
  /** When set, creates a debit only if a matching positive grant exists (reversal guard). */
  onlyIfPositiveGrant?: {
    reasonCode: string;
    referenceType: string;
    referenceId: string;
  };
};

/**
 * Idempotent positive point grants for eco / cleanup events.
 * Uses PointTransaction (userId + referenceType + referenceId + reasonCode) as dedupe key.
 * Call only from inside an interactive Prisma transaction alongside the business write.
 */
@Injectable()
export class EcoEventPointsService {
  /**
   * Credits [delta] to the user if no matching transaction exists. Returns amount actually awarded (0 or delta).
   */
  async creditIfNew(
    tx: Prisma.TransactionClient,
    params: EcoEventPointsCreditParams,
  ): Promise<number> {
    const { userId, delta, reasonCode, referenceType, referenceId } = params;
    if (delta <= 0) {
      return 0;
    }

    const existing = await tx.pointTransaction.findFirst({
      where: {
        userId,
        referenceType,
        referenceId,
        reasonCode,
      },
      select: { id: true },
    });
    if (existing != null) {
      return 0;
    }

    const user = await tx.user.findUnique({
      where: { id: userId },
      select: { pointsBalance: true, totalPointsEarned: true },
    });
    if (user == null) {
      return 0;
    }

    const balanceAfter = user.pointsBalance + delta;
    const totalEarnedAfter = user.totalPointsEarned + delta;

    await tx.pointTransaction.create({
      data: {
        userId,
        delta,
        balanceAfter,
        reasonCode,
        referenceType,
        referenceId,
      },
    });

    await tx.user.update({
      where: { id: userId },
      data: {
        pointsBalance: balanceAfter,
        totalPointsEarned: totalEarnedAfter,
      },
    });

    return delta;
  }

  /**
   * Applies a negative [delta] once per dedupe key. Returns amount applied (delta) or 0.
   */
  async debitOnceIfNew(
    tx: Prisma.TransactionClient,
    params: EcoEventPointsDebitParams,
  ): Promise<number> {
    const { userId, delta, reasonCode, referenceType, referenceId, onlyIfPositiveGrant } = params;
    if (delta >= 0) {
      return 0;
    }

    const existingDebit = await tx.pointTransaction.findFirst({
      where: {
        userId,
        referenceType,
        referenceId,
        reasonCode,
      },
      select: { id: true },
    });
    if (existingDebit != null) {
      return 0;
    }

    if (onlyIfPositiveGrant != null) {
      const grant = await tx.pointTransaction.findFirst({
        where: {
          userId,
          reasonCode: onlyIfPositiveGrant.reasonCode,
          referenceType: onlyIfPositiveGrant.referenceType,
          referenceId: onlyIfPositiveGrant.referenceId,
          delta: { gt: 0 },
        },
        select: { id: true },
      });
      if (grant == null) {
        return 0;
      }
    }

    const user = await tx.user.findUnique({
      where: { id: userId },
      select: { pointsBalance: true, totalPointsEarned: true },
    });
    if (user == null) {
      return 0;
    }

    const balanceAfter = user.pointsBalance + delta;
    const totalEarnedAfter = user.totalPointsEarned + delta;

    await tx.pointTransaction.create({
      data: {
        userId,
        delta,
        balanceAfter,
        reasonCode,
        referenceType,
        referenceId,
      },
    });

    await tx.user.update({
      where: { id: userId },
      data: {
        pointsBalance: balanceAfter,
        totalPointsEarned: totalEarnedAfter,
      },
    });

    return delta;
  }
}
