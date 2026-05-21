import { Injectable } from '@nestjs/common';
import { NotificationType, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import { ObservabilityStore } from '../observability/observability.store';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { ListNotificationsQueryDto } from './dto/list-notifications-query.dto';
import { NotificationActorDto } from './dto/notification-actor.dto';

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
  actor?: NotificationActorDto | null;
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
    private readonly reportsUpload: ReportsUploadService,
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
    const actorById = await this.resolveActorsForNotifications(notifications);
    return {
      data: notifications.map((n) => {
        const actorUserId = this.extractActorUserId(n.data);
        const actor =
          actorUserId != null ? actorById.get(actorUserId) ?? null : null;
        return {
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
          ...(actor != null ? { actor } : {}),
        };
      }),
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        unreadCount,
      },
    };
  }

  private extractActorUserId(data: unknown): string | null {
    if (data == null || typeof data !== 'object') return null;
    const record = data as Record<string, unknown>;
    const raw =
      record['actorUserId'] ?? record['highlightActorUserId'];
    if (typeof raw !== 'string' || raw.trim().length === 0) return null;
    return raw.trim();
  }

  private async resolveActorsForNotifications(
    notifications: Array<{ data: unknown }>,
  ): Promise<Map<string, NotificationActorDto>> {
    const actorIds = [
      ...new Set(
        notifications
          .map((n) => this.extractActorUserId(n.data))
          .filter((id): id is string => id != null),
      ),
    ];
    if (actorIds.length === 0) return new Map();

    const users = await this.prisma.user.findMany({
      where: { id: { in: actorIds } },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        avatarObjectKey: true,
      },
    });

    const avatarUrlByKey = new Map<string, string | null>();
    const signingTasks = new Map<string, Promise<string | null>>();
    for (const user of users) {
      const key = user.avatarObjectKey?.trim();
      if (!key) continue;
      if (!signingTasks.has(key)) {
        signingTasks.set(key, this.reportsUpload.signPrivateObjectKey(key));
      }
    }
    await Promise.all(
      [...signingTasks.entries()].map(async ([key, task]) => {
        avatarUrlByKey.set(key, await task);
      }),
    );

    const result = new Map<string, NotificationActorDto>();
    for (const user of users) {
      const displayName =
        `${user.firstName} ${user.lastName}`.trim() || user.id;
      const key = user.avatarObjectKey?.trim();
      const avatarUrl =
        key != null && key.length > 0
          ? (avatarUrlByKey.get(key) ?? null)
          : null;
      result.set(user.id, {
        id: user.id,
        displayName,
        avatarUrl,
      });
    }
    return result;
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
      const sameGroup =
        current.groupKey != null &&
        item.groupKey === current.groupKey &&
        Math.abs(
          new Date(current.createdAt).getTime() - new Date(item.createdAt).getTime(),
        ) < WINDOW_MS;

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
