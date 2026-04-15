import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

/** Rows older than this are safe to drop: clients should not replay the same idempotency key long after submit. */
const RETENTION_DAYS = 45;
const DAY_MS = 86_400_000;
const INTERVAL_MS = DAY_MS;

/**
 * Periodic cleanup for `ReportSubmitIdempotency` (see migration `20260415130000_report_submit_idempotency`).
 * Prevents the table from growing without bound while keeping a generous replay window after submission.
 */
@Injectable()
export class ReportSubmitIdempotencyCleanupService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ReportSubmitIdempotencyCleanupService.name);
  private interval?: NodeJS.Timeout;

  constructor(private readonly prisma: PrismaService) {}

  onModuleInit(): void {
    void this.runOnce().catch((err: unknown) => {
      this.logger.warn(`initial idempotency cleanup failed: ${String(err)}`);
    });
    this.interval = setInterval(() => {
      void this.runOnce().catch((err: unknown) => {
        this.logger.warn(`idempotency cleanup failed: ${String(err)}`);
      });
    }, INTERVAL_MS);
  }

  onModuleDestroy(): void {
    if (this.interval) {
      clearInterval(this.interval);
    }
  }

  private async runOnce(): Promise<void> {
    const cutoff = new Date(Date.now() - RETENTION_DAYS * DAY_MS);
    const result = await this.prisma.reportSubmitIdempotency.deleteMany({
      where: { createdAt: { lt: cutoff } },
    });
    if (result.count > 0) {
      this.logger.log(`removed ${result.count} stale report submit idempotency row(s)`);
    }
  }
}
