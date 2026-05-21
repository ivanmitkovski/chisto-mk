import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { EmailDeliveryOutboxService } from './email-delivery-outbox.service';

const POLL_MS = 10_000;

@Injectable()
export class EmailDeliveryWorkerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(EmailDeliveryWorkerService.name);
  private timer: ReturnType<typeof setTimeout> | null = null;
  private shuttingDown = false;
  private readonly workerId = `email-${process.pid}-${randomUUID().slice(0, 8)}`;

  constructor(private readonly outbox: EmailDeliveryOutboxService) {}

  onModuleInit(): void {
    this.scheduleTick(POLL_MS);
    this.logger.log('Email delivery worker started');
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
      this.logger.warn('Email outbox drain on shutdown failed', err);
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
    } catch (err) {
      this.logger.error('Email outbox processing error', err);
    }
    this.scheduleTick(POLL_MS);
  }
}
