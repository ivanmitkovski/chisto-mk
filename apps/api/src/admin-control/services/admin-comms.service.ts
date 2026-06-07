import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { EmailSuppressionService } from '../../email/services/email-suppression.service';

@Injectable()
export class AdminCommsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly suppression: EmailSuppressionService,
    private readonly audit?: AuditService,
  ) {}

  async listEmailSuppressions(
    page = 1,
    limit = 50,
    search?: string,
    reason?: string,
    source?: string,
  ) {
    const skip = (page - 1) * limit;
    const where = {
      ...(search?.trim()
        ? { email: { contains: search.trim(), mode: 'insensitive' as const } }
        : {}),
      ...(reason?.trim() ? { reason: reason.trim() } : {}),
      ...(source?.trim() ? { source: source.trim() } : {}),
    };
    const [data, total] = await this.prisma.$transaction([
      this.prisma.emailSuppression.findMany({ where, orderBy: { createdAt: 'desc' }, skip, take: limit }),
      this.prisma.emailSuppression.count({ where }),
    ]);
    return { data, meta: { page, limit, total } };
  }

  async createEmailSuppression(
    email: string,
    reason: string,
    actor: AuthenticatedUser,
  ) {
    const normalized = this.suppression.normalizeEmail(email);
    const row = await this.prisma.emailSuppression.upsert({
      where: { email: normalized },
      create: {
        email: normalized,
        reason,
        source: 'admin',
        payload: Prisma.JsonNull,
      },
      update: {
        reason,
        source: 'admin',
      },
    });
    await this.audit?.log({
      actorId: actor.userId,
      action: 'EMAIL_SUPPRESSION_CREATED',
      resourceType: 'EmailSuppression',
      resourceId: normalized,
      metadata: { reason, source: 'admin' },
    });
    return row;
  }

  async removeEmailSuppression(email: string, actor: AuthenticatedUser) {
    const existing = await this.prisma.emailSuppression.findUnique({ where: { email } });
    if (!existing) throw new NotFoundException('Suppression not found');
    await this.prisma.emailSuppression.delete({ where: { email } });
    await this.audit?.log({
      actorId: actor.userId,
      action: 'EMAIL_SUPPRESSION_REMOVED',
      resourceType: 'EmailSuppression',
      resourceId: email,
      metadata: { reason: existing.reason },
    });
    return { ok: true };
  }

  async listWebhookLogs(page = 1, limit = 50, action?: string) {
    const skip = (page - 1) * limit;
    const allowedActions = ['WEBHOOK_TWILIO_STATUS', 'WEBHOOK_POSTMARK', 'EMAIL_SUPPRESSION_CREATED'] as const;
    const where = {
      action: action?.trim() && allowedActions.includes(action.trim() as (typeof allowedActions)[number])
        ? action.trim()
        : { in: [...allowedActions] },
    };
    const [data, total] = await this.prisma.$transaction([
      this.prisma.auditLog.findMany({ where, orderBy: { createdAt: 'desc' }, skip, take: limit }),
      this.prisma.auditLog.count({ where }),
    ]);
    return { data, meta: { page, limit, total } };
  }
}
