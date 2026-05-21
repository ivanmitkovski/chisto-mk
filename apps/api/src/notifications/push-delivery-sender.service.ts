import { Inject, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FcmPushService } from './fcm-push.service';
import { ObservabilityStore } from '../observability/observability.store';

const MAX_ATTEMPTS = 5;
const BACKOFF_BASE_MS = 2_000;

type OutboxEntry = {
  id: string;
  userNotificationId: string;
  deviceToken: string;
  attempts: number;
  lastAttemptAt: Date | null;
  payload: unknown;
};

@Injectable()
export class PushDeliverySenderService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(FcmPushService) private readonly fcm: FcmPushService,
  ) {}

  computeNextRetryAt(attempt: number): Date {
    const backoffMs = BACKOFF_BASE_MS * Math.pow(2, Math.max(0, attempt - 1));
    const jitterMs = Math.floor(Math.random() * 750);
    return new Date(Date.now() + backoffMs + jitterMs);
  }

  async deliverClaimed(
    claimed: OutboxEntry[],
    userIdLookup: Map<string, string>,
  ): Promise<number> {
    let delivered = 0;
    for (const entry of claimed) {
      const minRetryAt = entry.lastAttemptAt
        ? new Date(entry.lastAttemptAt.getTime() + BACKOFF_BASE_MS * Math.pow(2, entry.attempts - 1))
        : new Date(0);

      if (new Date() < minRetryAt) {
        await this.prisma.notificationOutbox.update({
          where: { id: entry.id },
          data: { processingAt: null, leaseOwner: null },
        });
        continue;
      }

      const payload = entry.payload as {
        title: string;
        body: string;
        subtitle?: string;
        unreadCount?: number;
        data?: Record<string, string>;
      };
      const userId = userIdLookup.get(entry.userNotificationId);
      const result = await this.fcm.sendToToken(entry.deviceToken, {
        title: payload.title,
        body: payload.body,
        ...(payload.subtitle ? { subtitle: payload.subtitle } : {}),
        ...(payload.data ? { data: payload.data } : {}),
        ...(payload.unreadCount !== undefined ? { unreadCount: payload.unreadCount } : {}),
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
        if (userId && payload.unreadCount !== undefined) {
          void this.fcm.maybeSendBadgeSync(userId, entry.deviceToken, payload.unreadCount);
        }
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
    return delivered;
  }
}
