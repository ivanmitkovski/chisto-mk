import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FcmPushService } from './fcm-push.service';
import { ObservabilityStore } from '../observability/observability.store';

const MAX_ATTEMPTS = 5;
const BATCH_SIZE = 50;
const POLL_INTERVAL_MS = 5_000;
const BACKOFF_BASE_MS = 2_000;

@Injectable()
export class PushDeliveryWorkerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PushDeliveryWorkerService.name);
  private timer: ReturnType<typeof setInterval> | null = null;

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

    const pending = await this.prisma.notificationOutbox.findMany({
      where: {
        deliveredAt: null,
        failedPermanently: false,
        attempts: { lt: MAX_ATTEMPTS },
      },
      orderBy: { createdAt: 'asc' },
      take: BATCH_SIZE,
    });

    if (pending.length === 0) return 0;

    let delivered = 0;

    for (const entry of pending) {
      const minRetryAt = entry.lastAttemptAt
        ? new Date(entry.lastAttemptAt.getTime() + BACKOFF_BASE_MS * Math.pow(2, entry.attempts - 1))
        : new Date(0);

      if (new Date() < minRetryAt) continue;

      const payload = entry.payload as { title: string; body: string; data?: Record<string, string> };
      const result = await this.fcm.sendToToken(entry.deviceToken, payload);

      if (result.success) {
        await this.prisma.notificationOutbox.update({
          where: { id: entry.id },
          data: {
            deliveredAt: new Date(),
            attempts: entry.attempts + 1,
            lastAttemptAt: new Date(),
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
          failedPermanently: newAttempts >= MAX_ATTEMPTS,
        },
      });
      ObservabilityStore.recordPushQueueRetry();
    }

    return delivered;
  }
}
