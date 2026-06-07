import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AdminEmailOutboxStatus, AdminModerationCategory, Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { EmailService } from '../../email/services/email.service';
import type { EmailLocale, EmailTemplateId } from '../../email/types/email.types';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import { CATEGORY_TEMPLATE_ID } from '../constants/admin-moderation-email.constants';
import { AdminModerationEmailUnsubscribeTokenService } from './admin-moderation-email-unsubscribe-token.service';
import { buildAdminDeepLink } from '../util/admin-moderation-deep-link';

const MAX_ATTEMPTS = 5;
const BATCH_SIZE = 25;
const LEASE_TTL_MS = 60_000;

export type AdminModerationOutboxPayload = {
  firstName: string;
  deepLinkPath: string;
  emailContext: Record<string, unknown>;
};

@Injectable()
export class AdminModerationEmailOutboxService {
  private readonly logger = new Logger(AdminModerationEmailOutboxService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly emailService: EmailService,
    private readonly unsubscribeTokens: AdminModerationEmailUnsubscribeTokenService,
  ) {}

  async enqueueMany(
    rows: Array<{
      recipientUserId: string;
      recipientEmail: string;
      category: AdminModerationCategory;
      resourceId: string;
      payload: AdminModerationOutboxPayload;
    }>,
  ): Promise<number> {
    const templateId = (category: AdminModerationCategory): EmailTemplateId =>
      CATEGORY_TEMPLATE_ID[category];

    let inserted = 0;
    for (const row of rows) {
      const idempotencyKey = `${row.category}:${row.resourceId}:${row.recipientUserId}`;
      try {
        await this.prisma.adminEmailOutbox.create({
          data: {
            recipientUserId: row.recipientUserId,
            recipientEmail: row.recipientEmail,
            category: row.category,
            templateId: templateId(row.category),
            payload: row.payload as unknown as Prisma.InputJsonValue,
            idempotencyKey,
          },
        });
        inserted += 1;
      } catch (err) {
        if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
          continue;
        }
        throw err;
      }
    }
    return inserted;
  }

  async processOutbox(workerId: string): Promise<number> {
    const now = new Date();
    const runLeaseOwner = `${workerId}:${now.getTime()}`;
    const leaseExpiredBefore = new Date(now.getTime() - LEASE_TTL_MS);

    const pending = await this.prisma.adminEmailOutbox.findMany({
      where: {
        status: AdminEmailOutboxStatus.PENDING,
        attempts: { lt: MAX_ATTEMPTS },
        AND: [
          { OR: [{ nextAttemptAt: null }, { nextAttemptAt: { lte: now } }] },
          { OR: [{ processingAt: null }, { processingAt: { lte: leaseExpiredBefore } }] },
        ],
      },
      orderBy: { createdAt: 'asc' },
      take: BATCH_SIZE,
    });
    if (pending.length === 0) {
      return 0;
    }

    const claimableIds = pending.map((r) => r.id);
    const claimResult = await this.prisma.adminEmailOutbox.updateMany({
      where: {
        id: { in: claimableIds },
        status: AdminEmailOutboxStatus.PENDING,
        attempts: { lt: MAX_ATTEMPTS },
        AND: [
          { OR: [{ nextAttemptAt: null }, { nextAttemptAt: { lte: now } }] },
          { OR: [{ processingAt: null }, { processingAt: { lte: leaseExpiredBefore } }] },
        ],
      },
      data: { processingAt: now, leaseOwner: runLeaseOwner },
    });
    if (claimResult.count === 0) {
      return 0;
    }

    const claimed = await this.prisma.adminEmailOutbox.findMany({
      where: { id: { in: claimableIds }, leaseOwner: runLeaseOwner },
      orderBy: { createdAt: 'asc' },
      take: BATCH_SIZE,
    });

    let delivered = 0;
    for (const row of claimed) {
      const payload = row.payload as AdminModerationOutboxPayload;

      try {
        const localeByUser = await notificationLocalesByUserId(this.prisma, [row.recipientUserId]);
        const locale: EmailLocale = localeByUser.get(row.recipientUserId) === 'en' ? 'en' : 'mk';
        const actionUrl = buildAdminDeepLink(this.config, payload.deepLinkPath);
        const unsubscribeUrl = this.unsubscribeTokens.buildUnsubscribeUrl(
          row.recipientUserId,
          row.category,
        );

        await this.emailService.sendAdminModerationEmail(row.recipientEmail, {
          firstName: payload.firstName,
          templateId: row.templateId as EmailTemplateId,
          locale,
          context: { ...payload.emailContext, actionUrl },
          unsubscribeUrl,
        });
        await this.prisma.adminEmailOutbox.update({
          where: { id: row.id },
          data: {
            status: AdminEmailOutboxStatus.SENT,
            processingAt: null,
            leaseOwner: null,
            lastError: null,
          },
        });
        delivered += 1;
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        const attempts = row.attempts + 1;
        const failed = attempts >= MAX_ATTEMPTS;
        const backoffMs = Math.min(3_600_000, 30_000 * 2 ** attempts);
        await this.prisma.adminEmailOutbox.update({
          where: { id: row.id },
          data: {
            attempts,
            lastAttemptAt: new Date(),
            lastError: message.slice(0, 500),
            processingAt: null,
            leaseOwner: null,
            status: failed ? AdminEmailOutboxStatus.FAILED : AdminEmailOutboxStatus.PENDING,
            nextAttemptAt: failed ? null : new Date(Date.now() + backoffMs),
          },
        });
        if (failed) {
          this.logger.warn(
            `Admin moderation email outbox DLQ id=${row.id} user=${row.recipientUserId} template=${row.templateId}`,
          );
        }
      }
    }
    return delivered;
  }
}
