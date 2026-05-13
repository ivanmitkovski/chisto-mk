import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';

@Injectable()
export class NotificationStateService {
  constructor(private readonly prisma: PrismaService) {}

  async markOneRead(user: AuthenticatedUser, notificationId: string): Promise<void> {
    const notification = await this.prisma.userNotification.findFirst({
      where: { id: notificationId, userId: user.userId },
      select: { id: true, isRead: true },
    });

    if (!notification) {
      throw new NotFoundException({
        code: 'NOTIFICATION_NOT_FOUND',
        message: `Notification '${notificationId}' not found`,
      });
    }

    if (notification.isRead) return;

    await this.prisma.userNotification.update({
      where: { id: notificationId },
      data: { isRead: true },
    });
  }

  async markOneUnread(user: AuthenticatedUser, notificationId: string): Promise<void> {
    const notification = await this.prisma.userNotification.findFirst({
      where: { id: notificationId, userId: user.userId },
      select: { id: true, isRead: true },
    });

    if (!notification) {
      throw new NotFoundException({
        code: 'NOTIFICATION_NOT_FOUND',
        message: `Notification '${notificationId}' not found`,
      });
    }

    if (!notification.isRead) return;

    await this.prisma.userNotification.update({
      where: { id: notificationId },
      data: { isRead: false },
    });
  }

  async markAllRead(user: AuthenticatedUser): Promise<{ updated: number }> {
    const result = await this.prisma.userNotification.updateMany({
      where: { userId: user.userId, isRead: false },
      data: { isRead: true },
    });
    return { updated: result.count };
  }

  async archiveOne(user: AuthenticatedUser, notificationId: string): Promise<void> {
    const notification = await this.prisma.userNotification.findFirst({
      where: { id: notificationId, userId: user.userId },
      select: { id: true },
    });

    if (!notification) {
      throw new NotFoundException({
        code: 'NOTIFICATION_NOT_FOUND',
        message: `Notification '${notificationId}' not found`,
      });
    }

    await this.prisma.userNotification.update({
      where: { id: notificationId },
      data: { archivedAt: new Date() },
    });
  }

  async archiveAllRead(user: AuthenticatedUser): Promise<{ updated: number }> {
    const result = await this.prisma.userNotification.updateMany({
      where: { userId: user.userId, isRead: true, archivedAt: null },
      data: { archivedAt: new Date() },
    });
    return { updated: result.count };
  }
}
