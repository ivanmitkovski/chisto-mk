import { Inject, Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import type { Client } from 'pg';
import { NOTIFICATION_OUTBOX_ENQUEUED_CHANNEL } from '../../common/pg/outbox-pg-notify';
import { endPgOutboxListener, startPgOutboxListener } from '../../common/pg/start-pg-outbox-listener';
import { FcmPushService } from './fcm-push.service';
import { PushDeliveryOutboxService } from './push-delivery-outbox.service';

const POLL_ACTIVE_MS = 5_000;
const POLL_IDLE_MAX_MS = 60_000;
const POLL_SAFETY_LISTEN_IDLE_MS = 60_000;

@Injectable()
export class PushDeliveryWorkerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PushDeliveryWorkerService.name);
  private timer: ReturnType<typeof setTimeout> | null = null;
  private listenWakeTimer: ReturnType<typeof setTimeout> | null = null;
  private pgListenClient: Client | null = null;
  private pgListenConnected = false;
  private consecutiveIdleTicks = 0;
  private shuttingDown = false;
  private readonly workerId = `worker-${process.pid}-${randomUUID().slice(0, 8)}`;

  constructor(
    @Inject(FcmPushService) private readonly fcm: FcmPushService,
    private readonly outbox: PushDeliveryOutboxService,
  ) {}

  onModuleInit() {
    if (!this.fcm?.isEnabled()) {
      this.logger.log('Push delivery worker disabled — FCM not enabled');
      return;
    }

    void this.startPgListener();
    this.scheduleNextTick(2_000);
    this.logger.log('Push delivery worker started');
  }

  async onModuleDestroy() {
    this.shuttingDown = true;
    if (this.listenWakeTimer) {
      clearTimeout(this.listenWakeTimer);
      this.listenWakeTimer = null;
    }
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
    await endPgOutboxListener(this.pgListenClient);
    this.pgListenClient = null;
    this.pgListenConnected = false;
    try {
      await this.outbox.processOutbox(this.workerId);
    } catch (err) {
      this.logger.warn('Push outbox drain on shutdown failed', err);
    }
  }

  private async startPgListener(): Promise<void> {
    this.pgListenClient = await startPgOutboxListener({
      channel: NOTIFICATION_OUTBOX_ENQUEUED_CHANNEL,
      logger: this.logger,
      onNotify: () => this.scheduleWakeFromNotify(),
    });
    this.pgListenConnected = this.pgListenClient != null;
  }

  private scheduleWakeFromNotify(): void {
    if (this.listenWakeTimer != null) {
      clearTimeout(this.listenWakeTimer);
    }
    this.listenWakeTimer = setTimeout(() => {
      this.listenWakeTimer = null;
      this.consecutiveIdleTicks = 0;
      this.scheduleNextTick(50);
    }, 50);
  }

  private scheduleNextTick(delayMs: number): void {
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
    if (this.shuttingDown || !this.fcm?.isEnabled()) {
      return;
    }
    let delivered = 0;
    try {
      delivered = await this.outbox.processOutbox(this.workerId);
    } catch (err) {
      this.logger.error('Outbox processing error', err);
    }
    if (delivered > 0) {
      this.consecutiveIdleTicks = 0;
    } else {
      this.consecutiveIdleTicks = Math.min(this.consecutiveIdleTicks + 1, 10);
    }
    const jitter = Math.floor(Math.random() * 1_500);
    if (this.pgListenConnected) {
      if (delivered > 0) {
        this.scheduleNextTick(POLL_ACTIVE_MS + jitter);
      } else {
        this.scheduleNextTick(POLL_SAFETY_LISTEN_IDLE_MS + jitter);
      }
      return;
    }
    const idleExtra =
      this.consecutiveIdleTicks === 0
        ? 0
        : Math.min(POLL_IDLE_MAX_MS - POLL_ACTIVE_MS, POLL_ACTIVE_MS * this.consecutiveIdleTicks);
    this.scheduleNextTick(POLL_ACTIVE_MS + idleExtra + jitter);
  }

  /** Exposed for tests and manual drains. */
  processOutbox(): Promise<number> {
    return this.outbox.processOutbox(this.workerId);
  }
}
