import { Injectable, NotFoundException, Optional } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import { isEmailTerminalError } from '../util/email-error-codes';

@Injectable()
export class EmailDeadLetterRequeueService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly audit?: AuditService,
  ) {}

  async requeueAll(): Promise<{ requeued: number }> {
    const deadRows = await this.prisma.emailOutbox.findMany({
      where: { failedPermanently: true },
      select: { id: true, lastError: true },
    });
    const requeueIds = deadRows
      .filter((row) => this.isActionableDeadLetter(row.lastError))
      .map((row) => row.id);
    if (requeueIds.length === 0) {
      return { requeued: 0 };
    }

    const result = await this.prisma.emailOutbox.updateMany({
      where: { id: { in: requeueIds } },
      data: {
        failedPermanently: false,
        attempts: 0,
        nextRetryAt: null,
        processingAt: null,
        leaseOwner: null,
        lastError: null,
        deliveredAt: null,
      },
    });

    await this.audit?.log({
      actorId: null,
      action: 'EMAIL_DLQ_REQUEUE',
      resourceType: 'EmailOutbox',
      resourceId: 'bulk',
      metadata: { requeued: result.count },
    });

    return { requeued: result.count };
  }

  async requeueOne(id: string): Promise<{ requeued: boolean }> {
    const row = await this.prisma.emailOutbox.findFirst({
      where: { id, failedPermanently: true },
      select: { id: true, lastError: true },
    });
    if (!row) {
      throw new NotFoundException('Email dead letter not found');
    }
    if (!this.isActionableDeadLetter(row.lastError)) {
      return { requeued: false };
    }

    await this.prisma.emailOutbox.update({
      where: { id: row.id },
      data: {
        failedPermanently: false,
        attempts: 0,
        nextRetryAt: null,
        processingAt: null,
        leaseOwner: null,
        lastError: null,
        deliveredAt: null,
      },
    });

    await this.audit?.log({
      actorId: null,
      action: 'EMAIL_DLQ_REQUEUE',
      resourceType: 'EmailOutbox',
      resourceId: id,
      metadata: { requeued: true },
    });

    return { requeued: true };
  }

  async purgeTerminal(): Promise<{ purged: number }> {
    const deadRows = await this.prisma.emailOutbox.findMany({
      where: { failedPermanently: true },
      select: { id: true, lastError: true },
    });
    const purgeIds = deadRows
      .filter((row) => !this.isActionableDeadLetter(row.lastError))
      .map((row) => row.id);
    if (purgeIds.length === 0) {
      return { purged: 0 };
    }

    const result = await this.prisma.emailOutbox.deleteMany({
      where: { id: { in: purgeIds } },
    });

    await this.audit?.log({
      actorId: null,
      action: 'EMAIL_DLQ_PURGE',
      resourceType: 'EmailOutbox',
      resourceId: 'bulk',
      metadata: { purged: result.count },
    });

    return { purged: result.count };
  }

  private isActionableDeadLetter(lastError: string | null): boolean {
    return !isEmailTerminalError(lastError);
  }
}
