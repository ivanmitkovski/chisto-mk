import { Inject, Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import type { Client } from 'pg';
import { NOTIFICATION_OUTBOX_ENQUEUED_CHANNEL } from '../common/pg/outbox-pg-notify';
import { endPgOutboxListener, startPgOutboxListener } from '../common/pg/start-pg-outbox-listener';
import { PrismaService } from '../prisma/prisma.service';
import { FcmPushService } from './fcm-push.service';
import { ObservabilityStore } from '../observability/observability.store';

const MAX_ATTEMPTS = 5;
const BATCH_SIZE = 50;
const POLL_ACTIVE_MS = 5_000;
const POLL_IDLE_MAX_MS = 60_000;
/** When LISTEN is active, idle ticks use this safety poll instead of tight polling. */
const POLL_SAFETY_LISTEN_IDLE_MS = 60_000;
const BACKOFF_BASE_MS = 2_000;
const LEASE_TTL_MS = 30_000;

@Injectable()
export class PushDeliveryWorkerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PushDeliveryWorkerService.name);
  private timer: ReturnType<typeof setTimeout> | null = null;
  private listenWakeTimer: ReturnType<typeof setTimeout> | null = null;
  private pgListenClient: Client | null = null;
  private pgListenConnected = false;
  private consecutiveIdleTicks = 0;
  private readonly workerId = `worker-${process.pid}-${randomUUID().slice(0, 8)}`;

  constructor(
    private readonly prisma: PrismaService,
    @Inject(FcmPushService) private readonly fcm: FcmPushService,
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
    if (this.timer) {
      clearTimeout(this.timer);
    }
    this.timer = setTimeout(() => {
      void this.runTick();
    }, delayMs);
  }

  private async runTick(): Promise<void> {
    if (!this.fcm?.isEnabled()) {
      return;
    }
    let delivered = 0;
    try {
      delivered = await this.processOutbox();
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

  async processOutbox(): Promise<number> {
    if (!this.fcm?.isReady()) return 0;

    await this.refreshQueueStats();
    const now = new Date();
    const runLeaseOwner = `${this.workerId}:${now.getTime()}`;
    const leaseExpiredBefore = new Date(now.getTime() - LEASE_TTL_MS);
    const pending = await this.prisma.notificationOutbox.findMany({
      where: {
        deliveredAt: null,
        failedPermanently: false,
        attempts: { lt: MAX_ATTEMPTS },
        AND: [
          { OR: [{ nextRetryAt: null }, { nextRetryAt: { lte: now } }] },
          { OR: [{ processingAt: null }, { processingAt: { lte: leaseExpiredBefore } }] },
        ],
      },
      orderBy: { createdAt: 'asc' },
      take: BATCH_SIZE,
    });

    if (pending.length === 0) {
      await this.refreshQueueStats();
      return 0;
    }
    const claimableIds = pending.map((row) => row.id);
    const claimResult = await this.prisma.notificationOutbox.updateMany({
      where: {
        id: { in: claimableIds },
        deliveredAt: null,
        failedPermanently: false,
        attempts: { lt: MAX_ATTEMPTS },
        AND: [
          { OR: [{ nextRetryAt: null }, { nextRetryAt: { lte: now } }] },
          { OR: [{ processingAt: null }, { processingAt: { lte: leaseExpiredBefore } }] },
        ],
      },
      data: {
        processingAt: now,
        leaseOwner: runLeaseOwner,
      },
    });
    if (claimResult.count === 0) {
      await this.refreshQueueStats();
      return 0;
    }

    const claimed = await this.prisma.notificationOutbox.findMany({
      where: {
        id: { in: claimableIds },
        leaseOwner: runLeaseOwner,
      },
      orderBy: { createdAt: 'asc' },
      take: BATCH_SIZE,
    });
    if (claimed.length === 0) {
      await this.refreshQueueStats();
      return 0;
    }

    const notificationIds = [...new Set(claimed.map((e) => e.userNotificationId))];
    const userIdLookup = new Map<string, string>();
    if (notificationIds.length > 0) {
      const notifRows = await this.prisma.userNotification.findMany({
        where: { id: { in: notificationIds } },
        select: { id: true, userId: true },
      });
      for (const r of notifRows) {
        userIdLookup.set(r.id, r.userId);
      }
    }

    let delivered = 0;

    for (const entry of claimed) {
      const minRetryAt = entry.lastAttemptAt
        ? new Date(entry.lastAttemptAt.getTime() + BACKOFF_BASE_MS * Math.pow(2, entry.attempts - 1))
        : new Date(0);

      if (new Date() < minRetryAt) {
        await this.prisma.notificationOutbox.update({
          where: { id: entry.id },
          data: {
            processingAt: null,
            leaseOwner: null,
          },
        });
        continue;
      }

      const payload = entry.payload as { title: string; body: string; data?: Record<string, string> };
      const userId = userIdLookup.get(entry.userNotificationId);
      const result = await this.fcm.sendToToken(entry.deviceToken, {
        ...payload,
        ...(userId ? { userId } : {}),
      });

      if (result.success) {
        await this.prisma.notificationOutbox.update({
          where: { id: entry.id },
          data: {
            deliveredAt: new Date(),
            attempts: entry.attempts + 1,
            lastAttemptAt: new Date(),
            processingAt: null,
            leaseOwner: null,
            nextRetryAt: null,
            lastErrorCode: null,
            lastErrorMessage: null,
          },
        });
        delivered += 1;
        continue;
      }

      if (result.shouldRevoke) {
        await this.fcm.revokeToken(entry.deviceToken);
        await this.prisma.notificationOutbox.update({
          where: { id: entry.id },
          data: {
            failedPermanently: true,
            attempts: entry.attempts + 1,
            lastAttemptAt: new Date(),
            processingAt: null,
            leaseOwner: null,
            lastErrorCode: 'TOKEN_REVOKED',
            lastErrorMessage: 'Push token revoked or invalid',
          },
        });
        continue;
      }

      await this.fcm.incrementFailureCount(entry.deviceToken);
      const newAttempts = entry.attempts + 1;
      await this.prisma.notificationOutbox.update({
        where: { id: entry.id },
        data: {
          attempts: newAttempts,
          lastAttemptAt: new Date(),
          processingAt: null,
          leaseOwner: null,
          nextRetryAt: this.computeNextRetryAt(newAttempts),
          failedPermanently: newAttempts >= MAX_ATTEMPTS,
          lastErrorCode: 'FCM_SEND_FAILED',
          lastErrorMessage: `Transient FCM error after attempt ${newAttempts}`,
        },
      });
      ObservabilityStore.recordPushQueueRetry();
    }

    await this.refreshQueueStats();
    return delivered;
  }

  private computeNextRetryAt(attempt: number): Date {
    const backoffMs = BACKOFF_BASE_MS * Math.pow(2, Math.max(0, attempt - 1));
    const jitterMs = Math.floor(Math.random() * 750);
    return new Date(Date.now() + backoffMs + jitterMs);
  }

  private async refreshQueueStats(): Promise<void> {
    const [queueDepth, activeLeases, deadLetterCount] = await this.prisma.$transaction([
      this.prisma.notificationOutbox.count({
        where: { deliveredAt: null, failedPermanently: false },
      }),
      this.prisma.notificationOutbox.count({
        where: { processingAt: { not: null } },
      }),
      this.prisma.notificationOutbox.count({
        where: { failedPermanently: true },
      }),
    ]);
    ObservabilityStore.setPushQueueStats({
      queueDepth,
      activeLeases,
      deadLetterCount,
    });
  }
}
