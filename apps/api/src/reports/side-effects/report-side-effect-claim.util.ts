import { ReportSideEffectStatus } from '../../prisma-client';
import type { PrismaService } from '../../prisma/prisma.service';

/** Stale PROCESSING rows are reclaimed after this lease TTL. */
export const REPORT_SIDE_EFFECT_LEASE_MS = 15 * 60 * 1000;

export function reportSideEffectLeaseOwner(): string {
  return `api:${process.pid}:${Date.now()}`;
}

export function staleReportSideEffectBefore(now = Date.now()): Date {
  return new Date(now - REPORT_SIDE_EFFECT_LEASE_MS);
}

/**
 * Atomically claims a side-effect row for processing. Returns false if another worker holds a live lease.
 */
export async function claimReportSideEffect(
  prisma: PrismaService,
  effectId: string,
  leaseOwner: string,
): Promise<boolean> {
  const staleBefore = staleReportSideEffectBefore();
  const result = await prisma.reportSideEffect.updateMany({
    where: {
      id: effectId,
      OR: [
        { status: ReportSideEffectStatus.PENDING },
        { status: ReportSideEffectStatus.FAILED },
        {
          status: ReportSideEffectStatus.PROCESSING,
          OR: [{ processingAt: null }, { processingAt: { lte: staleBefore } }],
        },
      ],
    },
    data: {
      status: ReportSideEffectStatus.PROCESSING,
      processingAt: new Date(),
      leaseOwner,
      attempts: { increment: 1 },
    },
  });
  return result.count === 1;
}

export function reportSideEffectRetryWhere(
  maxAttempts: number,
  staleBefore: Date,
): {
  OR: Array<Record<string, unknown>>;
} {
  return {
    OR: [
      {
        status: ReportSideEffectStatus.PENDING,
        attempts: { lt: maxAttempts },
      },
      {
        status: ReportSideEffectStatus.FAILED,
        attempts: { lt: maxAttempts },
      },
      {
        status: ReportSideEffectStatus.PROCESSING,
        attempts: { lt: maxAttempts },
        OR: [{ processingAt: null }, { processingAt: { lte: staleBefore } }],
      },
    ],
  };
}
