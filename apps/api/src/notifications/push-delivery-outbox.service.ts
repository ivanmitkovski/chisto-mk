import { Inject, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FcmPushService } from './fcm-push.service';
import { ObservabilityStore } from '../observability/observability.store';
import { PushDeliverySenderService } from './push-delivery-sender.service';

const MAX_ATTEMPTS = 5;
const BATCH_SIZE = 50;
const LEASE_TTL_MS = 30_000;

@Injectable()
export class PushDeliveryOutboxService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(FcmPushService) private readonly fcm: FcmPushService,
    private readonly sender: PushDeliverySenderService,
  ) {}

  async processOutbox(workerId: string): Promise<number> {
    if (!this.fcm?.isReady()) return 0;

    await this.refreshQueueStats();
    const now = new Date();
    const runLeaseOwner = `${workerId}:${now.getTime()}`;
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

    const delivered = await this.sender.deliverClaimed(claimed, userIdLookup);
    await this.refreshQueueStats();
    return delivered;
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
