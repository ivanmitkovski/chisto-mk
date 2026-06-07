import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { AdminModerationEmailOutboxService } from './admin-moderation-email-outbox.service';

const POLL_MS = 10_000;
const MAX_POLL_MS = 300_000;

@Injectable()
export class AdminModerationEmailWorkerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AdminModerationEmailWorkerService.name);
  private timer: ReturnType<typeof setTimeout> | null = null;
  private shuttingDown = false;
  private currentPollMs = POLL_MS;
  private readonly workerId = `admin-mod-email-${process.pid}-${randomUUID().slice(0, 8)}`;

  constructor(private readonly outbox: AdminModerationEmailOutboxService) {}

  onModuleInit(): void {
    this.scheduleTick(POLL_MS);
    this.logger.log('Admin moderation email worker started');
  }

  async onModuleDestroy(): Promise<void> {
    this.shuttingDown = true;
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
    try {
      await this.outbox.processOutbox(this.workerId);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.warn(`Admin moderation email outbox drain on shutdown failed: ${message}`);
    }
  }

  private scheduleTick(delayMs: number): void {
    if (this.shuttingDown) {
      return;
    }
    if (this.timer) {
      clearTimeout(this.timer);
    }
    this.timer = setTimeout(() => {
      void this.runTick();
    }, delayMs);
  }

  private async runTick(): Promise<void> {
    if (this.shuttingDown) {
      return;
    }
    try {
      await this.outbox.processOutbox(this.workerId);
      this.currentPollMs = POLL_MS;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(
        `Admin moderation email outbox worker tick failed (next retry in ${this.currentPollMs}ms): ${message}`,
        err instanceof Error ? err.stack : undefined,
      );
      this.currentPollMs = Math.min(this.currentPollMs * 2, MAX_POLL_MS);
    }
    this.scheduleTick(this.currentPollMs);
  }
}
