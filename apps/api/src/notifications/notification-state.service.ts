import { Injectable, NotFoundException } from '@nestjs/common';
import { NotificationType } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { NotificationsRoomEmitterService } from './notifications-room-emitter.service';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import { ObservabilityStore } from '../observability/observability.store';

@Injectable()
export class NotificationStateService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly roomEmitter: NotificationsRoomEmitterService,
    private readonly featureFlags: FeatureFlagsService,
  ) {}

  private async unreadCountFor(userId: string): Promise<number> {
    return this.prisma.userNotification.count({
      where: { userId, isRead: false, archivedAt: null },
    });
  }

  private async emitIfRealtime(
    userId: string,
    emit: (unreadCount: number) => void,
  ): Promise<void> {
    if (!(await this.featureFlags.isPushRealtimeSocketEnabled())) return;
    const unreadCount = await this.unreadCountFor(userId);
    emit(unreadCount);
  }

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

    await this.emitIfRealtime(user.userId, (unreadCount) => {
      this.roomEmitter.emitNotificationRead(user.userId, {
        id: notificationId,
        unreadCount,
      });
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

    await this.emitIfRealtime(user.userId, (unreadCount) => {
      this.roomEmitter.emitNotificationRead(user.userId, {
        id: notificationId,
        unreadCount,
      });
    });
  }

  /** Marks all unread EVENT_CHAT inbox rows for one event (groupKey `event-chat:<eventId>`). */
  async markEventChatGroupRead(
    userId: string,
    eventId: string,
  ): Promise<{ updated: number; unreadCount: number }> {
    const groupKey = `event-chat:${eventId}`;
    const result = await this.prisma.userNotification.updateMany({
      where: {
        userId,
        type: NotificationType.EVENT_CHAT,
        groupKey,
        isRead: false,
        archivedAt: null,
      },
      data: { isRead: true },
    });

    const unreadCount = await this.unreadCountFor(userId);
    if (result.count > 0) {
      await this.emitIfRealtime(userId, (count) => {
        this.roomEmitter.emitNotificationRead(userId, { unreadCount: count });
      });
    }

    return { updated: result.count, unreadCount };
  }

  async markAllRead(user: AuthenticatedUser): Promise<{ updated: number }> {
    const result = await this.prisma.userNotification.updateMany({
      where: { userId: user.userId, isRead: false },
      data: { isRead: true },
    });

    await this.emitIfRealtime(user.userId, (unreadCount) => {
      this.roomEmitter.emitNotificationReadAll(user.userId, { unreadCount });
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

    await this.emitIfRealtime(user.userId, (unreadCount) => {
      this.roomEmitter.emitNotificationArchived(user.userId, {
        id: notificationId,
        unreadCount,
      });
    });
  }

  async archiveAllRead(user: AuthenticatedUser): Promise<{ updated: number }> {
    const result = await this.prisma.userNotification.updateMany({
      where: { userId: user.userId, isRead: true, archivedAt: null },
      data: { archivedAt: new Date() },
    });
    return { updated: result.count };
  }

  async recordOpened(user: AuthenticatedUser, notificationId: string): Promise<void> {
    const notification = await this.prisma.userNotification.findFirst({
      where: { id: notificationId, userId: user.userId },
      select: { id: true, openedAt: true },
    });

    if (!notification) {
      throw new NotFoundException({
        code: 'NOTIFICATION_NOT_FOUND',
        message: `Notification '${notificationId}' not found`,
      });
    }

    if (notification.openedAt) return;

    await this.prisma.userNotification.update({
      where: { id: notificationId },
      data: { openedAt: new Date(), isRead: true },
    });

    ObservabilityStore.recordPushInboxRead();

    await this.emitIfRealtime(user.userId, (unreadCount) => {
      this.roomEmitter.emitNotificationRead(user.userId, {
        id: notificationId,
        unreadCount,
      });
    });
  }
}
