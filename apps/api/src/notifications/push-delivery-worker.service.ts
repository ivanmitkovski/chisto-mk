import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { FcmPushService } from './fcm-push.service';
import { ObservabilityStore } from '../observability/observability.store';

const MAX_ATTEMPTS = 5;
const BATCH_SIZE = 50;
const POLL_INTERVAL_MS = 5_000;
const BACKOFF_BASE_MS = 2_000;
const LEASE_TTL_MS = 30_000;

@Injectable()
export class PushDeliveryWorkerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PushDeliveryWorkerService.name);
  private timer: ReturnType<typeof setInterval> | null = null;
  private readonly workerId = `worker-${process.pid}-${randomUUID().slice(0, 8)}`;

  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmPushService,
  ) {}

  onModuleInit() {
    if (!this.fcm.isEnabled()) {
      this.logger.log('Push delivery worker disabled — FCM not enabled');
      return;
    }

    this.timer = setInterval(() => {
      this.processOutbox().catch((err) =>
        this.logger.error('Outbox processing error', err),
      );
    }, POLL_INTERVAL_MS);
    this.logger.log('Push delivery worker started');
  }

  onModuleDestroy() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async processOutbox(): Promise<number> {
    if (!this.fcm.isReady()) return 0;

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
      const result = await this.fcm.sendToToken(entry.deviceToken, payload);

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
