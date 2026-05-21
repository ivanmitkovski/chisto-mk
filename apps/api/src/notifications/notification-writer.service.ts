import { Injectable } from '@nestjs/common';
import { NotificationType, Prisma } from '../prisma-client';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationPreferencesService } from './notification-preferences.service';

const NOTIFICATION_THREAD_DEDUPE_MS = 120_000;

export type CreateNotificationResult = {
  id: string;
  updated: boolean;
};

@Injectable()
export class NotificationWriterService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly featureFlags: FeatureFlagsService,
    private readonly preferences: NotificationPreferencesService,
  ) {}

  async createNotification(input: {
    userId: string;
    title: string;
    body: string;
    type: NotificationType;
    data?: Record<string, unknown>;
    threadKey?: string;
    groupKey?: string;
  }): Promise<CreateNotificationResult | null> {
    if (!(await this.featureFlags.isNotificationsInboxEnabled())) return null;
    if (await this.preferences.isTypeMuted(input.userId, input.type)) return null;

    const groupKey = input.groupKey?.trim();
    if (input.type === NotificationType.EVENT_CHAT && groupKey != null && groupKey.length > 0) {
      return this.upsertEventChatGroupNotification(input, groupKey);
    }

    const threadKey = input.threadKey?.trim();

    if (threadKey != null && threadKey.length > 0) {
      const since = new Date(Date.now() - NOTIFICATION_THREAD_DEDUPE_MS);
      const duplicate = await this.prisma.userNotification.findFirst({
        where: {
          userId: input.userId,
          type: input.type,
          threadKey,
          createdAt: { gte: since },
        },
        select: { id: true },
      });
      if (duplicate != null) {
        return null;
      }
    }

    const notification = await this.prisma.userNotification.create({
      data: {
        userId: input.userId,
        title: input.title,
        body: input.body,
        type: input.type,
        ...(threadKey ? { threadKey } : {}),
        ...(groupKey ? { groupKey } : {}),
        ...(input.data ? { data: input.data as Prisma.InputJsonValue } : {}),
      },
      select: { id: true },
    });
    return { id: notification.id, updated: false };
  }

  private async upsertEventChatGroupNotification(
    input: {
      userId: string;
      title: string;
      body: string;
      type: NotificationType;
      data?: Record<string, unknown>;
      threadKey?: string;
      groupKey?: string;
    },
    groupKey: string,
  ): Promise<CreateNotificationResult | null> {
    const threadKey = input.threadKey?.trim();

    const existing = await this.prisma.userNotification.findFirst({
      where: {
        userId: input.userId,
        type: NotificationType.EVENT_CHAT,
        groupKey,
        isRead: false,
        archivedAt: null,
      },
      orderBy: { createdAt: 'desc' },
      select: { id: true, data: true },
    });

    if (existing != null) {
      const mergedData = this.mergeEventChatNotificationData(existing.data, input.data);
      await this.prisma.userNotification.update({
        where: { id: existing.id },
        data: {
          title: input.title,
          body: input.body,
          ...(threadKey ? { threadKey } : {}),
          createdAt: new Date(),
          data: mergedData as Prisma.InputJsonValue,
        },
      });
      return { id: existing.id, updated: true };
    }

    const notification = await this.prisma.userNotification.create({
      data: {
        userId: input.userId,
        title: input.title,
        body: input.body,
        type: NotificationType.EVENT_CHAT,
        groupKey,
        ...(threadKey ? { threadKey } : {}),
        data: this.initialEventChatNotificationData(input.data) as Prisma.InputJsonValue,
      },
      select: { id: true },
    });
    return { id: notification.id, updated: false };
  }

  private initialEventChatNotificationData(
    incoming?: Record<string, unknown>,
  ): Record<string, unknown> {
    const base = { ...(incoming ?? {}) };
    const rawCount = base['messageCount'];
    if (rawCount == null) {
      base['messageCount'] = 1;
    }
    return base;
  }

  private mergeEventChatNotificationData(
    existingData: unknown,
    incoming?: Record<string, unknown>,
  ): Record<string, unknown> {
    const prev =
      existingData != null && typeof existingData === 'object' && !Array.isArray(existingData)
        ? (existingData as Record<string, unknown>)
        : {};
    const next = { ...prev, ...(incoming ?? {}) };
    const prevCount = this.parseMessageCount(prev['messageCount']) ?? 1;
    const incomingCount = this.parseMessageCount(incoming?.['messageCount']);
    next['messageCount'] =
      incomingCount != null && incomingCount > prevCount ? incomingCount : prevCount + 1;
    return next;
  }

  private parseMessageCount(raw: unknown): number | null {
    if (raw == null) return null;
    if (typeof raw === 'number' && Number.isFinite(raw)) return Math.max(1, Math.floor(raw));
    if (typeof raw === 'string') {
      const parsed = Number(raw);
      return Number.isFinite(parsed) ? Math.max(1, Math.floor(parsed)) : null;
    }
    return null;
  }
}
