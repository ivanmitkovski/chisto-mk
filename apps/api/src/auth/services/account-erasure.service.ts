import { Injectable } from '@nestjs/common';
import { createHash, randomBytes } from 'crypto';
import { UserStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthSessionRevocationService } from './auth-session-revocation.service';

const NOTIFICATION_ERASE_BATCH_SIZE = 500;

@Injectable()
export class AccountErasureService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sessionRevocation: AuthSessionRevocationService,
  ) {}

  async eraseUserAccount(userId: string): Promise<void> {
    const placeholder = `deleted_${createHash('sha256').update(userId).digest('hex').slice(0, 16)}`;
    const now = new Date();

    await this.sessionRevocation.revokeAllForUser(userId, 'account_deleted');

    await this.prisma.$transaction(async (tx) => {
      await tx.userDeviceToken.deleteMany({ where: { userId } });
      for (;;) {
        const batch = await tx.userNotification.findMany({
          where: { userId },
          select: { id: true },
          take: NOTIFICATION_ERASE_BATCH_SIZE,
        });
        if (batch.length === 0) {
          break;
        }
        const ids = batch.map((n) => n.id);
        await tx.notificationOutbox.deleteMany({
          where: { userNotificationId: { in: ids } },
        });
        await tx.userNotification.deleteMany({
          where: { id: { in: ids } },
        });
      }

      await tx.siteComment.updateMany({
        where: { authorId: userId },
        data: {
          body: '[removed]',
          isDeleted: true,
        },
      });

      await tx.eventChatMessage.updateMany({
        where: { authorId: userId },
        data: {
          body: '[removed]',
          deletedAt: now,
        },
      });

      await tx.user.update({
        where: { id: userId },
        data: {
          status: UserStatus.DELETED,
          deletedAt: now,
          firstName: 'Deleted',
          lastName: 'User',
          email: `${placeholder}@anonymized.invalid`,
          phoneNumber: `+000${randomBytes(4).toString('hex')}`,
          passwordHash: randomBytes(32).toString('hex'),
          avatarObjectKey: null,
          homeLatitude: null,
          homeLongitude: null,
          homeLocationLabel: null,
          totpSecret: null,
          mfaBackupCodes: [],
        },
      });
    });
  }
}
