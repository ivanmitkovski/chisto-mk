import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import type { NotificationEvent } from '../../notifications/types/notification-event.types';
import { ObservabilityStore } from '../../observability/observability.store';
import { EmailService } from './email.service';
import { mapNotificationEventToEmail } from '../util/email-event-mapper';
import { isImportantNotificationEmail } from '../util/email-importance.policy';

const MAX_ATTEMPTS = 5;
const BATCH_SIZE = 25;
const LEASE_TTL_MS = 60_000;

export type EmailOutboxPayload = {
  event: Omit<NotificationEvent, 'recipientUserIds'>;
};

@Injectable()
export class EmailDeliveryOutboxService {
  private readonly logger = new Logger(EmailDeliveryOutboxService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly emailService: EmailService,
  ) {}

  async enqueue(
    userId: string,
    notificationId: string,
    event: Omit<NotificationEvent, 'recipientUserIds'>,
  ): Promise<void> {
    if (!isImportantNotificationEmail(event)) {
      return;
    }
    const mapped = mapNotificationEventToEmail(event);
    if (!mapped) {
      return;
    }
    const payload: EmailOutboxPayload = { event };
    try {
      await this.prisma.emailOutbox.create({
        data: {
          userId,
          templateId: mapped.templateId,
          payload: payload as unknown as Prisma.InputJsonValue,
          idempotencyKey: `${notificationId}:email`,
        },
      });
    } catch (err) {
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        return;
      }
      throw err;
    }
  }

  async processOutbox(workerId: string): Promise<number> {
    const now = new Date();
    const runLeaseOwner = `${workerId}:${now.getTime()}`;
    const leaseExpiredBefore = new Date(now.getTime() - LEASE_TTL_MS);
    const pending = await this.prisma.emailOutbox.findMany({
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
    const claimResult = await this.prisma.emailOutbox.updateMany({
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
      data: { processingAt: now, leaseOwner: runLeaseOwner },
    });
    if (claimResult.count === 0) {
      return 0;
    }

    const claimed = await this.prisma.emailOutbox.findMany({
      where: { id: { in: claimableIds }, leaseOwner: runLeaseOwner },
      orderBy: { createdAt: 'asc' },
      take: BATCH_SIZE,
    });

    let delivered = 0;
    for (const row of claimed) {
      const payload = row.payload as EmailOutboxPayload;
      try {
        await this.emailService.sendForNotificationEvent(row.userId, payload.event);
        await this.prisma.emailOutbox.update({
          where: { id: row.id },
          data: {
            deliveredAt: new Date(),
            processingAt: null,
            leaseOwner: null,
            lastError: null,
          },
        });
        delivered += 1;
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        const attempts = row.attempts + 1;
        const failedPermanently = attempts >= MAX_ATTEMPTS;
        const backoffMs = Math.min(3_600_000, 30_000 * 2 ** attempts);
        await this.prisma.emailOutbox.update({
          where: { id: row.id },
          data: {
            attempts,
            lastAttemptAt: new Date(),
            lastError: message.slice(0, 500),
            processingAt: null,
            leaseOwner: null,
            failedPermanently,
            nextRetryAt: failedPermanently ? null : new Date(Date.now() + backoffMs),
          },
        });
        if (failedPermanently) {
          this.logger.warn(`Email outbox DLQ id=${row.id} user=${row.userId} template=${row.templateId}`);
        }
      }
    }
    await this.refreshQueueStats();
    return delivered;
  }

  async listDeadLetters(page = 1, limit = 20) {
    const safePage = Math.max(1, page);
    const safeLimit = Math.min(100, Math.max(1, limit));
    const skip = (safePage - 1) * safeLimit;
    const [rows, total] = await this.prisma.$transaction([
      this.prisma.emailOutbox.findMany({
        where: { failedPermanently: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: safeLimit,
        select: {
          id: true,
          userId: true,
          templateId: true,
          attempts: true,
          lastError: true,
          lastAttemptAt: true,
          createdAt: true,
        },
      }),
      this.prisma.emailOutbox.count({
        where: { failedPermanently: true },
      }),
    ]);
    return {
      data: rows.map((row) => ({
        id: row.id,
        userId: row.userId,
        templateId: row.templateId,
        attempts: row.attempts,
        lastError: row.lastError,
        lastAttemptAt: row.lastAttemptAt?.toISOString() ?? null,
        createdAt: row.createdAt.toISOString(),
      })),
      meta: {
        page: safePage,
        limit: safeLimit,
        total,
      },
    };
  }

  private async refreshQueueStats(): Promise<void> {
    const [queueDepth, deadLetterCount] = await this.prisma.$transaction([
      this.prisma.emailOutbox.count({
        where: {
          deliveredAt: null,
          failedPermanently: false,
        },
      }),
      this.prisma.emailOutbox.count({
        where: { failedPermanently: true },
      }),
    ]);
    ObservabilityStore.setEmailQueueStats({ queueDepth, deadLetterCount });
  }
}
