import { Injectable, NotFoundException, Optional } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import { FCM_REVOKE_ERROR_CODES } from '../util/fcm-error-codes';

@Injectable()
export class PushDeadLetterRequeueService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly audit?: AuditService,
  ) {}

  async requeueAll(): Promise<{ requeued: number }> {
    const deadRows = await this.prisma.notificationOutbox.findMany({
      where: { failedPermanently: true },
      select: { id: true, deviceToken: true, lastErrorCode: true },
    });
    const candidateIds = deadRows
      .filter((row) => this.isActionableDeadLetter(row.deviceToken, row.lastErrorCode))
      .map((row) => row.id);
    if (candidateIds.length === 0) {
      return { requeued: 0 };
    }

    const candidateTokens = [...new Set(
      deadRows
        .filter((row) => candidateIds.includes(row.id))
        .map((row) => row.deviceToken),
    )];
    const activeRows = await this.prisma.userDeviceToken.findMany({
      where: { token: { in: candidateTokens }, revokedAt: null },
      select: { token: true },
    });
    const activeTokens = new Set(activeRows.map((row) => row.token));
    const requeueIds = deadRows
      .filter(
        (row) =>
          candidateIds.includes(row.id) && activeTokens.has(row.deviceToken),
      )
      .map((row) => row.id);

    if (requeueIds.length === 0) {
      return { requeued: 0 };
    }

    const result = await this.prisma.notificationOutbox.updateMany({
      where: { id: { in: requeueIds } },
      data: {
        failedPermanently: false,
        attempts: 0,
        nextRetryAt: null,
        processingAt: null,
        leaseOwner: null,
        lastErrorCode: null,
        lastErrorMessage: null,
        deliveredAt: null,
      },
    });

    await this.audit?.log({
      actorId: null,
      action: 'PUSH_DLQ_REQUEUE',
      resourceType: 'NotificationOutbox',
      resourceId: 'bulk',
      metadata: { requeued: result.count },
    });

    return { requeued: result.count };
  }

  async requeueOne(id: string): Promise<{ requeued: boolean }> {
    const row = await this.prisma.notificationOutbox.findFirst({
      where: { id, failedPermanently: true },
      select: { id: true, deviceToken: true, lastErrorCode: true },
    });
    if (!row) {
      throw new NotFoundException('Dead letter not found');
    }
    if (!this.isActionableDeadLetter(row.deviceToken, row.lastErrorCode)) {
      return { requeued: false };
    }

    const active = await this.prisma.userDeviceToken.findFirst({
      where: { token: row.deviceToken, revokedAt: null },
      select: { token: true },
    });
    if (!active) {
      return { requeued: false };
    }

    await this.prisma.notificationOutbox.update({
      where: { id: row.id },
      data: {
        failedPermanently: false,
        attempts: 0,
        nextRetryAt: null,
        processingAt: null,
        leaseOwner: null,
        lastErrorCode: null,
        lastErrorMessage: null,
        deliveredAt: null,
      },
    });

    await this.audit?.log({
      actorId: null,
      action: 'PUSH_DLQ_REQUEUE',
      resourceType: 'NotificationOutbox',
      resourceId: id,
      metadata: { requeued: true },
    });

    return { requeued: true };
  }

  async purgeTerminal(): Promise<{ purged: number }> {
    const deadRows = await this.prisma.notificationOutbox.findMany({
      where: { failedPermanently: true },
      select: { id: true, deviceToken: true, lastErrorCode: true },
    });
    if (deadRows.length === 0) {
      return { purged: 0 };
    }

    const tokens = [...new Set(deadRows.map((row) => row.deviceToken))];
    const revokedRows = await this.prisma.userDeviceToken.findMany({
      where: { token: { in: tokens }, revokedAt: { not: null } },
      select: { token: true },
    });
    const revokedTokens = new Set(revokedRows.map((row) => row.token));

    const terminalIds = deadRows
      .filter(
        (row) =>
          revokedTokens.has(row.deviceToken) ||
          (row.lastErrorCode != null && FCM_REVOKE_ERROR_CODES.has(row.lastErrorCode)),
      )
      .map((row) => row.id);

    if (terminalIds.length === 0) {
      return { purged: 0 };
    }

    const result = await this.prisma.notificationOutbox.deleteMany({
      where: { id: { in: terminalIds } },
    });

    await this.audit?.log({
      actorId: null,
      action: 'PUSH_DLQ_PURGE',
      resourceType: 'NotificationOutbox',
      resourceId: 'bulk',
      metadata: { purged: result.count },
    });

    return { purged: result.count };
  }

  private isActionableDeadLetter(_deviceToken: string, lastErrorCode: string | null): boolean {
    if (lastErrorCode != null && FCM_REVOKE_ERROR_CODES.has(lastErrorCode)) {
      return false;
    }
    return true;
  }
}
