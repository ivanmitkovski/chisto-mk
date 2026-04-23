import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationType, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ObservabilityStore } from '../observability/observability.store';
import { ListNotificationsQueryDto } from './dto/list-notifications-query.dto';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferenceDto } from './dto/update-notification-preference.dto';

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

type NotificationPreferenceItem = {
  type: NotificationType;
  muted: boolean;
  mutedUntil: string | null;
};

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  async listForUser(
    user: AuthenticatedUser,
    query: ListNotificationsQueryDto,
  ): Promise<NotificationListResponse> {
    if (!(await this.isInboxEnabled())) {
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
      ...(query.onlyUnread ? { isRead: false } : {}),
    };

    const skip = (query.page - 1) * query.limit;

    const [notifications, total, unreadCount] = await this.prisma.$transaction([
      this.prisma.userNotification.findMany({
        where,
        skip,
        take: query.limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.userNotification.count({ where }),
      this.prisma.userNotification.count({
        where: { userId: user.userId, isRead: false },
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
    if (!(await this.isInboxEnabled())) return { unreadCount: 0 };
    const unreadCount = await this.prisma.userNotification.count({
      where: { userId: user.userId, isRead: false },
    });
    return { unreadCount };
  }

  async markOneRead(user: AuthenticatedUser, notificationId: string): Promise<void> {
    if (!(await this.isInboxEnabled())) return;
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

  async markAllRead(user: AuthenticatedUser): Promise<{ updated: number }> {
    if (!(await this.isInboxEnabled())) return { updated: 0 };
    const result = await this.prisma.userNotification.updateMany({
      where: { userId: user.userId, isRead: false },
      data: { isRead: true },
    });
    return { updated: result.count };
  }

  async listPreferences(
    user: AuthenticatedUser,
  ): Promise<{ data: NotificationPreferenceItem[] }> {
    const rows = await this.prisma.userNotificationPreference.findMany({
      where: { userId: user.userId },
      select: { type: true, muted: true, mutedUntil: true },
    });
    const byType = new Map<NotificationType, { muted: boolean; mutedUntil: Date | null }>();
    for (const row of rows) {
      byType.set(row.type, { muted: row.muted, mutedUntil: row.mutedUntil });
    }
    const data = Object.values(NotificationType).map((type) => {
      const pref = byType.get(type);
      return {
        type,
        muted: pref?.muted ?? false,
        mutedUntil: pref?.mutedUntil?.toISOString() ?? null,
      };
    });
    return { data };
  }

  async updatePreference(
    user: AuthenticatedUser,
    type: NotificationType,
    dto: UpdateNotificationPreferenceDto,
  ): Promise<NotificationPreferenceItem> {
    const parsedMutedUntil =
      dto.mutedUntil != null && dto.mutedUntil.trim() !== ''
        ? new Date(dto.mutedUntil)
        : null;
    const mutedUntil = dto.muted && parsedMutedUntil && !Number.isNaN(parsedMutedUntil.getTime())
      ? parsedMutedUntil
      : null;
    const row = await this.prisma.userNotificationPreference.upsert({
      where: {
        userId_type: { userId: user.userId, type },
      },
      create: {
        userId: user.userId,
        type,
        muted: dto.muted,
        mutedUntil,
      },
      update: {
        muted: dto.muted,
        mutedUntil,
      },
      select: {
        type: true,
        muted: true,
        mutedUntil: true,
      },
    });
    return {
      type: row.type,
      muted: row.muted,
      mutedUntil: row.mutedUntil?.toISOString() ?? null,
    };
  }

  async registerDeviceToken(
    user: AuthenticatedUser,
    dto: RegisterDeviceTokenDto,
  ): Promise<{ id: string }> {
    const existing = await this.prisma.userDeviceToken.findUnique({
      where: { token: dto.token },
      select: { id: true, userId: true, revokedAt: true },
    });

    if (existing) {
      const updated = await this.prisma.userDeviceToken.update({
        where: { id: existing.id },
        data: {
          userId: user.userId,
          platform: dto.platform,
          appVersion: dto.appVersion ?? null,
          locale: dto.locale ?? null,
          lastSeenAt: new Date(),
          revokedAt: null,
          failureCount: 0,
        },
        select: { id: true },
      });
      return { id: updated.id };
    }

    const created = await this.prisma.userDeviceToken.create({
      data: {
        userId: user.userId,
        token: dto.token,
        platform: dto.platform,
        appVersion: dto.appVersion ?? null,
        locale: dto.locale ?? null,
      },
      select: { id: true },
    });
    return { id: created.id };
  }

  async unregisterDeviceToken(
    user: AuthenticatedUser,
    token: string,
  ): Promise<void> {
    const existing = await this.prisma.userDeviceToken.findUnique({
      where: { token },
      select: { id: true, userId: true },
    });

    if (!existing || existing.userId !== user.userId) return;

    await this.prisma.userDeviceToken.update({
      where: { id: existing.id },
      data: { revokedAt: new Date() },
    });
  }

  async createNotification(input: {
    userId: string;
    title: string;
    body: string;
    type: NotificationType;
    data?: Record<string, unknown>;
    threadKey?: string;
    groupKey?: string;
  }): Promise<string> {
    if (!(await this.isInboxEnabled())) return '';
    if (await this.isTypeMuted(input.userId, input.type)) return '';
    /** Absorb duplicate staff/push emissions (retries, double handlers) for the same logical thread. */
    const NOTIFICATION_THREAD_DEDUPE_MS = 120_000;
    if (input.threadKey != null && input.threadKey.trim().length > 0) {
      const since = new Date(Date.now() - NOTIFICATION_THREAD_DEDUPE_MS);
      const duplicate = await this.prisma.userNotification.findFirst({
        where: {
          userId: input.userId,
          type: input.type,
          threadKey: input.threadKey,
          createdAt: { gte: since },
        },
        select: { id: true },
      });
      if (duplicate != null) {
        return '';
      }
    }
    const notification = await this.prisma.userNotification.create({
      data: {
        userId: input.userId,
        title: input.title,
        body: input.body,
        type: input.type,
        ...(input.threadKey ? { threadKey: input.threadKey } : {}),
        ...(input.groupKey ? { groupKey: input.groupKey } : {}),
        ...(input.data ? { data: input.data as Prisma.InputJsonValue } : {}),
      },
      select: { id: true },
    });
    return notification.id;
  }

  async getActiveTokensForUser(userId: string) {
    return this.prisma.userDeviceToken.findMany({
      where: { userId, revokedAt: null },
      select: { id: true, token: true, platform: true },
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

  private async isTypeMuted(
    userId: string,
    type: NotificationType,
  ): Promise<boolean> {
    const pref = await this.prisma.userNotificationPreference.findUnique({
      where: { userId_type: { userId, type } },
      select: { muted: true, mutedUntil: true },
    });
    if (!pref?.muted) return false;
    if (pref.mutedUntil == null) return true;
    if (pref.mutedUntil.getTime() > Date.now()) return true;
    await this.prisma.userNotificationPreference.update({
      where: { userId_type: { userId, type } },
      data: { muted: false, mutedUntil: null },
    });
    return false;
  }

  private async isInboxEnabled(): Promise<boolean> {
    const fromEnv = this.configService.get<string>('NOTIFICATIONS_INBOX_ENABLED', 'true') === 'true';
    const row = await this.prisma.featureFlag.findUnique({
      where: { key: 'notifications_inbox_enabled' },
      select: { enabled: true },
    });
    return row?.enabled ?? fromEnv;
  }
}
