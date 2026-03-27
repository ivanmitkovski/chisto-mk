import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { ConfigService } from '@nestjs/config';
import { NotificationType, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from './notifications.service';
import { FcmPushService } from './fcm-push.service';

export type NotificationEvent = {
  recipientUserIds: string[];
  title: string;
  body: string;
  type: NotificationType;
  data?: Record<string, unknown>;
  threadKey?: string;
  groupKey?: string;
};

@Injectable()
export class NotificationDispatcherService {
  private readonly logger = new Logger(NotificationDispatcherService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly fcm: FcmPushService,
    private readonly configService: ConfigService,
  ) {}

  @OnEvent('notification.send')
  async handleNotificationEvent(event: NotificationEvent): Promise<void> {
    for (const userId of event.recipientUserIds) {
      try {
        await this.dispatchToUser(userId, event);
      } catch (error) {
        this.logger.error(`Failed to dispatch notification to user ${userId}`, error);
      }
    }
  }

  async dispatchToUser(
    userId: string,
    event: Omit<NotificationEvent, 'recipientUserIds'>,
  ): Promise<void> {
    const notificationId = await this.notificationsService.createNotification({
      userId,
      title: event.title,
      body: event.body,
      type: event.type,
      ...(event.threadKey ? { threadKey: event.threadKey } : {}),
      ...(event.groupKey ? { groupKey: event.groupKey } : {}),
      ...(event.data ? { data: event.data } : {}),
    });
    if (!notificationId) return;

    if (!(await this.isPushEnabled()) || !this.fcm.isReady()) return;

    const tokens = await this.notificationsService.getActiveTokensForUser(userId);
    if (tokens.length === 0) return;

    const pushData: Record<string, string> = {
      notificationId,
      type: event.type,
      ...(event.data
        ? Object.fromEntries(
            Object.entries(event.data).map(([k, v]) => [k, String(v)]),
          )
        : {}),
    };

    const outboxEntries = tokens.map((t) => ({
      userNotificationId: notificationId,
      deviceToken: t.token,
      payload: { title: event.title, body: event.body, data: pushData } as unknown as Prisma.InputJsonValue,
      idempotencyKey: `${notificationId}:${t.token}`,
    }));

    await this.prisma.notificationOutbox.createMany({
      data: outboxEntries,
      skipDuplicates: true,
    });

    await this.prisma.userNotification.update({
      where: { id: notificationId },
      data: { sentAt: new Date() },
    });
  }

  private async isPushEnabled(): Promise<boolean> {
    const fromEnv = this.configService.get<string>('PUSH_FCM_ENABLED', 'false') === 'true';
    const row = await this.prisma.featureFlag.findUnique({
      where: { key: 'push_fcm_enabled' },
      select: { enabled: true },
    });
    return row?.enabled ?? fromEnv;
  }
}
