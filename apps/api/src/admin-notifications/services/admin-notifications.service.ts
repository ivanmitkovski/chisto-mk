import { Injectable, NotFoundException } from '@nestjs/common';
import { AdminNotification, Prisma } from '../../prisma-client';
import { formatRelativeTimeSince } from '../../common/utils/format-relative-time-since';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ListAdminNotificationsQueryDto } from '../dto/list-admin-notifications.dto';

type AdminNotificationListItem = Pick<
  AdminNotification,
  | 'id'
  | 'title'
  | 'message'
  | 'timeLabel'
  | 'tone'
  | 'category'
  | 'isUnread'
  | 'href'
  | 'messageTemplateKey'
  | 'messageTemplateParams'
> & {
  /** ISO 8601 — clients should prefer this for display (browser locale, live updates). */
  createdAt: string;
};

type AdminNotificationListResponse = {
  data: AdminNotificationListItem[];
  meta: {
    page: number;
    limit: number;
    total: number;
    unreadCount: number;
  };
};

const adminNotificationListSelect = {
  id: true,
  title: true,
  message: true,
  timeLabel: true,
  tone: true,
  category: true,
  isUnread: true,
  href: true,
  createdAt: true,
} satisfies Prisma.AdminNotificationSelect;

type SelectedAdminNotification = Prisma.AdminNotificationGetPayload<{
  select: typeof adminNotificationListSelect;
}>;

function normalizeAdminNotificationHref(href: string | null): string | null {
  if (!href) return null;
  if (href.startsWith('/dashboard/')) return href;
  if (href === '/moderation/ugc') return '/dashboard/moderation/ugc';
  if (href.startsWith('/moderation/ugc?')) {
    return `/dashboard${href}`;
  }
  if (href.startsWith('/')) return href;
  return null;
}

@Injectable()
export class AdminNotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async listForAdmin(
    admin: AuthenticatedUser,
    query: ListAdminNotificationsQueryDto,
    locale = 'en',
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
        select: adminNotificationListSelect,
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

    const now = new Date();
    const effectiveLocale = locale.trim() || 'en';

    const items: AdminNotificationListItem[] = notifications.map(
      (notification: SelectedAdminNotification) => ({
        id: notification.id,
        title: notification.title,
        message: notification.message,
        timeLabel: formatRelativeTimeSince(notification.createdAt, now, effectiveLocale),
        createdAt: notification.createdAt.toISOString(),
        tone: notification.tone,
        category: notification.category,
        isUnread: notification.isUnread,
        href: normalizeAdminNotificationHref(notification.href),
        messageTemplateKey: null,
        messageTemplateParams: null,
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

