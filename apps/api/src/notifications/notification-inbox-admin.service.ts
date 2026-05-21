import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationInboxAdminService {
  constructor(private readonly prisma: PrismaService) {}

  async countSentNotifications(): Promise<number> {
    return this.prisma.userNotification.count({
      where: { sentAt: { not: null } },
    });
  }

  async countOpenedNotifications(): Promise<number> {
    return this.prisma.userNotification.count({
      where: { openedAt: { not: null } },
    });
  }

  async listDeadLetters(page = 1, limit = 20) {
    const safePage = Math.max(1, page);
    const safeLimit = Math.min(100, Math.max(1, limit));
    const skip = (safePage - 1) * safeLimit;
    const [rows, total] = await this.prisma.$transaction([
      this.prisma.notificationOutbox.findMany({
        where: { failedPermanently: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: safeLimit,
        select: {
          id: true,
          userNotificationId: true,
          deviceToken: true,
          attempts: true,
          lastErrorCode: true,
          lastErrorMessage: true,
          lastAttemptAt: true,
          createdAt: true,
        },
      }),
      this.prisma.notificationOutbox.count({
        where: { failedPermanently: true },
      }),
    ]);
    return {
      data: rows.map((row) => ({
        id: row.id,
        userNotificationId: row.userNotificationId,
        deviceTokenSuffix: row.deviceToken.slice(-8),
        attempts: row.attempts,
        lastErrorCode: row.lastErrorCode,
        lastErrorMessage: row.lastErrorMessage,
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
}
