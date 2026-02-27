import { Injectable, NotFoundException } from '@nestjs/common';
import { AdminNotification, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ListAdminNotificationsQueryDto } from './dto/list-admin-notifications.dto';

type AdminNotificationListItem = Pick<
  AdminNotification,
  'id' | 'title' | 'message' | 'timeLabel' | 'tone' | 'category' | 'isUnread' | 'href'
>;

type AdminNotificationListResponse = {
  data: AdminNotificationListItem[];
  meta: {
    page: number;
    limit: number;
    total: number;
    unreadCount: number;
  };
};

@Injectable()
export class AdminNotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async listForAdmin(
    admin: AuthenticatedUser,
    query: ListAdminNotificationsQueryDto,
  ): Promise<AdminNotificationListResponse> {
    const where: Prisma.AdminNotificationWhereInput = {
      OR: [{ userId: admin.userId }, { userId: null }],
      ...(query.onlyUnread ? { isUnread: true } : {}),
      ...(query.category ? { category: query.category } : {}),
    };

    const skip = (query.page - 1) * query.limit;

    const [notifications, total, unreadCount] = await this.prisma.$transaction([
      this.prisma.adminNotification.findMany({
        where,
        skip,
        take: query.limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.adminNotification.count({ where }),
      this.prisma.adminNotification.count({
        where: {
          OR: [{ userId: admin.userId }, { userId: null }],
          isUnread: true,
        },
      }),
    ]);

    const items: AdminNotificationListItem[] = notifications.map(
      (notification) => ({
        id: notification.id,
        title: notification.title,
        message: notification.message,
        timeLabel: notification.timeLabel,
        tone: notification.tone,
        category: notification.category,
        isUnread: notification.isUnread,
        href: notification.href ?? null,
      }),
    );

    return {
      data: items,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        unreadCount,
      },
    };
  }

  async markOneRead(admin: AuthenticatedUser, notificationId: string): Promise<void> {
    const notification = await this.prisma.adminNotification.findFirst({
      where: {
        id: notificationId,
        OR: [{ userId: admin.userId }, { userId: null }],
      },
      select: { id: true, isUnread: true },
    });

    if (!notification) {
      throw new NotFoundException({
        code: 'NOTIFICATION_NOT_FOUND',
        message: `Notification with id '${notificationId}' was not found`,
      });
    }

    if (!notification.isUnread) {
      return;
    }

    await this.prisma.adminNotification.update({
      where: { id: notificationId },
      data: { isUnread: false },
    });
  }

  async markAllRead(admin: AuthenticatedUser): Promise<{ updated: number }> {
    const result = await this.prisma.adminNotification.updateMany({
      where: {
        OR: [{ userId: admin.userId }, { userId: null }],
        isUnread: true,
      },
      data: { isUnread: false },
    });

    return { updated: result.count };
  }
}

