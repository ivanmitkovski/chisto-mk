import { Injectable } from '@nestjs/common';
import { NotificationType, Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { FeatureFlagsService } from '../../feature-flags/services/feature-flags.service';
import { ObservabilityStore } from '../../observability/observability.store';
import { ListNotificationsQueryDto } from '../dto/list-notifications-query.dto';
import { NotificationInboxActorsService } from './notification-inbox-actors.service';
import { NotificationInboxAdminService } from './notification-inbox-admin.service';
import {
  collapseByGroupKey,
  inboxListSelect,
  mapInboxRow,
  type NotificationListItem,
} from '../util/notification-inbox.mapper';

type NotificationListResponse = {
  data: NotificationListItem[];
  meta: {
    page: number;
    limit: number;
    total: number;
    unreadCount: number;
  };
};

@Injectable()
export class NotificationInboxService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly featureFlags: FeatureFlagsService,
    private readonly inboxActors: NotificationInboxActorsService,
    private readonly inboxAdmin: NotificationInboxAdminService,
  ) {}

  async listForUser(
    user: AuthenticatedUser,
    query: ListNotificationsQueryDto,
  ): Promise<NotificationListResponse> {
    if (!(await this.featureFlags.isNotificationsInboxEnabled())) {
      return {
        data: [],
        meta: {
          page: query.page,
          limit: query.limit,
          total: 0,
          unreadCount: 0,
        },
      };
    }
    const where: Prisma.UserNotificationWhereInput = {
      userId: user.userId,
      archivedAt: null,
      ...(query.onlyUnread ? { isRead: false } : {}),
    };

    const skip = (query.page - 1) * query.limit;

    const [notifications, total, unreadCount] = await this.prisma.$transaction([
      this.prisma.userNotification.findMany({
        where,
        skip,
        take: query.limit,
        orderBy: { createdAt: 'desc' },
        select: inboxListSelect,
      }),
      this.prisma.userNotification.count({ where }),
      this.prisma.userNotification.count({
        where: { userId: user.userId, isRead: false, archivedAt: null },
      }),
    ]);

    ObservabilityStore.recordPushInboxRead();
    const actorById = await this.inboxActors.resolveActorsForNotifications(notifications);
    return {
      data: notifications.map((n) => mapInboxRow(n, actorById)),
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        unreadCount,
      },
    };
  }

  async getUnreadCount(user: AuthenticatedUser): Promise<{ unreadCount: number }> {
    if (!(await this.featureFlags.isNotificationsInboxEnabled())) return { unreadCount: 0 };
    const unreadCount = await this.prisma.userNotification.count({
      where: { userId: user.userId, isRead: false, archivedAt: null },
    });
    return { unreadCount };
  }

  async getSummary(
    user: AuthenticatedUser,
  ): Promise<{ data: Array<{ type: NotificationType; total: number; unread: number }> }> {
    if (!(await this.featureFlags.isNotificationsInboxEnabled())) return { data: [] };
    const rows = await this.prisma.userNotification.groupBy({
      by: ['type', 'isRead'],
      where: { userId: user.userId, archivedAt: null },
      _count: true,
    });
    const map = new Map<NotificationType, { total: number; unread: number }>();
    for (const row of rows) {
      const entry = map.get(row.type) ?? { total: 0, unread: 0 };
      entry.total += row._count;
      if (!row.isRead) entry.unread += row._count;
      map.set(row.type, entry);
    }
    const data = Object.values(NotificationType).map((type) => ({
      type,
      total: map.get(type)?.total ?? 0,
      unread: map.get(type)?.unread ?? 0,
    }));
    return { data };
  }

  async listGrouped(user: AuthenticatedUser, query: ListNotificationsQueryDto) {
    const rawResult = await this.listForUser(user, query);
    const grouped = collapseByGroupKey(rawResult.data);
    return { ...rawResult, data: grouped };
  }

  countSentNotifications(): Promise<number> {
    return this.inboxAdmin.countSentNotifications();
  }

  countOpenedNotifications(): Promise<number> {
    return this.inboxAdmin.countOpenedNotifications();
  }

  listDeadLetters(page?: number, limit?: number) {
    return this.inboxAdmin.listDeadLetters(page, limit);
  }
}
