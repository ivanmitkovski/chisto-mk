import { Injectable } from '@nestjs/common';
import { NotificationType, Prisma } from '../prisma-client';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationPreferencesService } from './notification-preferences.service';

const NOTIFICATION_THREAD_DEDUPE_MS = 120_000;

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
  }): Promise<string> {
    if (!(await this.featureFlags.isNotificationsInboxEnabled())) return '';
    if (await this.preferences.isTypeMuted(input.userId, input.type)) return '';

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

}
