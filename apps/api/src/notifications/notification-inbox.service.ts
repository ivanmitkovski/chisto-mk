import { Injectable } from '@nestjs/common';
import { NotificationType, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import { ObservabilityStore } from '../observability/observability.store';
import { ListNotificationsQueryDto } from './dto/list-notifications-query.dto';

type NotificationListItem = {
  id: string;
  title: string;
  body: string;
  type: NotificationType;
  isRead: boolean;
  data: unknown;
  createdAt: string;
  sentAt: string | null;
  threadKey: string | null;
  groupKey: string | null;
  archivedAt: string | null;
};

type NotificationListResponse = {
  data: NotificationListItem[];
  meta: {
    page: number;
    limit: number;
    total: number;
    unreadCount: number;
  };
};

type DeadLetterListResponse = {
  data: Array<{
    id: string;
    userNotificationId: string;
    deviceTokenSuffix: string;
    attempts: number;
    lastErrorCode: string | null;
    lastErrorMessage: string | null;
    lastAttemptAt: string | null;
    createdAt: string;
  }>;
  meta: {
    page: number;
    limit: number;
    total: number;
  };
};

const inboxListSelect = {
  id: true,
  title: true,
  body: true,
  type: true,
  isRead: true,
  data: true,
  createdAt: true,
  sentAt: true,
  threadKey: true,
  groupKey: true,
  archivedAt: true,
} as const;

@Injectable()
export class NotificationInboxService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly featureFlags: FeatureFlagsService,
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
    return {
      data: notifications.map((n) => ({
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        isRead: n.isRead,
        data: n.data,
        createdAt: n.createdAt.toISOString(),
        sentAt: n.sentAt?.toISOString() ?? null,
        threadKey: n.threadKey ?? null,
        groupKey: n.groupKey ?? null,
        archivedAt: n.archivedAt?.toISOString() ?? null,
      })),
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

  async listGrouped(
    user: AuthenticatedUser,
    query: ListNotificationsQueryDto,
  ) {
    const rawResult = await this.listForUser(user, query);
    const grouped = this.collapseByGroupKey(rawResult.data);
    return { ...rawResult, data: grouped };
  }

  private collapseByGroupKey(
    items: NotificationListItem[],
  ): Array<NotificationListItem & { groupCount: number }> {
    if (items.length === 0) return [];
    const result: Array<NotificationListItem & { groupCount: number }> = [];
    let current = items[0];
    let groupCount = 1;
    const WINDOW_MS = 24 * 60 * 60 * 1000;

    for (let i = 1; i < items.length; i++) {
      const item = items[i];
      const sameGroup = current.groupKey != null
        && item.groupKey === current.groupKey
        && Math.abs(new Date(current.createdAt).getTime() - new Date(item.createdAt).getTime()) < WINDOW_MS;

      if (sameGroup) {
        groupCount++;
      } else {
        result.push({ ...current, groupCount });
        current = item;
        groupCount = 1;
      }
    }
    result.push({ ...current, groupCount });
    return result;
  }

  async listDeadLetters(page = 1, limit = 20): Promise<DeadLetterListResponse> {
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
