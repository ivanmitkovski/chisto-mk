import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ReportSideEffectKind } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { ReportSideEffectProcessorService } from './report-side-effect-processor.service';
import {
  reportSideEffectRetryWhere,
  staleReportSideEffectBefore,
} from './report-side-effect-claim.util';

const POLL_MS = 15_000;
const MAX_ATTEMPTS = 5;

function backoffMs(attempts: number): number {
  return Math.min(60_000 * 2 ** Math.max(0, attempts), 30 * 60_000);
}

@Injectable()
export class ReportSideEffectRetryService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ReportSideEffectRetryService.name);
  private timer: ReturnType<typeof setInterval> | null = null;
  private running = false;
  private shuttingDown = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly processor: ReportSideEffectProcessorService,
  ) {}

  onModuleInit(): void {
    if (process.env.NODE_ENV === 'test') return;
    this.timer = setInterval(() => void this.tick(), POLL_MS);
  }

  onModuleDestroy(): void {
    this.shuttingDown = true;
    if (this.timer) clearInterval(this.timer);
    void this.tick({ force: true });
  }

  private async tick(opts?: { force?: boolean }): Promise<void> {
    if (this.running) return;
    if (this.shuttingDown && !opts?.force) return;
    this.running = true;
    try {
      const row = await this.prisma.reportSideEffect.findFirst({
        where: reportSideEffectRetryWhere(MAX_ATTEMPTS, staleReportSideEffectBefore()),
        orderBy: { createdAt: 'asc' },
      });
      if (!row) return;

      const delay = backoffMs(row.attempts);
      const age = Date.now() - row.updatedAt.getTime();
      if (age < delay) return;

      if (row.kind === ReportSideEffectKind.MERGE_DUPLICATE_POST) {
        await this.processor.processMergeDuplicatePost(row.id);
      } else if (row.kind === ReportSideEffectKind.MODERATION_STATUS_POST) {
        await this.processor.processModerationStatusPost(row.id);
      }
    } catch (err) {
      this.logger.warn(
        `ReportSideEffect retry tick error: ${err instanceof Error ? err.message : String(err)}`,
      );
    } finally {
      this.running = false;
    }
  }
}
