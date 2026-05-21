import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { ConfigService } from '@nestjs/config';
import { isPgOutboxNotifyEnabled, NOTIFY_SQL } from '../common/pg/outbox-pg-notify';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationWriterService } from './notification-writer.service';
import { DeviceTokenService } from './device-token.service';
import { FcmPushService } from './fcm-push.service';
import { buildFcmDataPayload } from './notification-push-data';
import type { NotificationEvent } from './notification-event.types';
import { EmailService } from '../email/email.service';
import { NotificationsRoomEmitterService } from './notifications-room-emitter.service';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import { resolveInterruptionLevel } from './fcm-apns-payload';
import { computeQuietHoursDeferral } from './notification-quiet-hours';
import { shouldDeferVisiblePush } from './notification-push-rate-limit';

export type { NotificationEvent } from './notification-event.types';

@Injectable()
export class NotificationDispatcherService {
  private readonly logger = new Logger(NotificationDispatcherService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly writer: NotificationWriterService,
    private readonly deviceTokens: DeviceTokenService,
    private readonly fcm: FcmPushService,
    private readonly configService: ConfigService,
    private readonly emailService: EmailService,
    private readonly roomEmitter: NotificationsRoomEmitterService,
    private readonly featureFlags: FeatureFlagsService,
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
    const written = await this.writer.createNotification({
      userId,
      title: event.title,
      body: event.body,
      type: event.type,
      ...(event.threadKey ? { threadKey: event.threadKey } : {}),
      ...(event.groupKey ? { groupKey: event.groupKey } : {}),
      ...(event.data ? { data: event.data } : {}),
    });

    if (written == null) {
      return;
    }

    const notificationId = written.id;
    const unreadCount = await this.prisma.userNotification.count({
      where: { userId, isRead: false, archivedAt: null },
    });

    if (await this.featureFlags.isPushRealtimeSocketEnabled()) {
      const row = await this.prisma.userNotification.findUnique({
        where: { id: notificationId },
        select: {
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
        },
      });
      if (row) {
        const payload = {
          notification: {
            ...row,
            createdAt: row.createdAt.toISOString(),
            sentAt: row.sentAt?.toISOString() ?? null,
            archivedAt: row.archivedAt?.toISOString() ?? null,
          },
          unreadCount,
        };
        if (written.updated) {
          this.roomEmitter.emitNotificationUpdated(userId, payload);
        } else {
          this.roomEmitter.emitNotificationNew(userId, payload);
        }
      }
    }

    if (!(await this.isPushEnabled()) || !this.fcm.isReady()) {
      void this.emailService.sendForNotificationEvent(userId, event).catch((err: unknown) => {
        this.logger.warn(
          `Transactional email failed for user ${userId}: ${err instanceof Error ? err.message : String(err)}`,
        );
      });
      return;
    }

    const tokens = await this.deviceTokens.getActiveTokensForUser(userId);
    if (tokens.length === 0) {
      void this.emailService.sendForNotificationEvent(userId, event).catch(() => {});
      return;
    }

    const pushData = buildFcmDataPayload(
      notificationId,
      event.type,
      {
        ...event.data,
        ...(event.threadKey ? { threadKey: event.threadKey } : {}),
        ...(event.groupKey ? { groupKey: event.groupKey } : {}),
        notificationType: String(event.type),
      },
      { unreadCount, title: event.title, body: event.body },
    );

    const interruption = resolveInterruptionLevel(pushData) as
      | 'time-sensitive'
      | 'active'
      | 'passive';

    let nextRetryAt: Date | null = null;
    if (await this.featureFlags.isPushQuietHoursEnabled()) {
      const prefs = await this.prisma.userNotificationPreference.findFirst({
        where: { userId },
        select: {
          quietHoursStart: true,
          quietHoursEnd: true,
          quietHoursTimezone: true,
        },
      });
      if (prefs) {
        nextRetryAt = computeQuietHoursDeferral(prefs, interruption);
      }
    }

    if (!nextRetryAt && shouldDeferVisiblePush(userId, String(event.type))) {
      nextRetryAt = new Date(Date.now() + 60_000);
      pushData['kind'] = 'digest_deferred';
    }

    const outboxEntries = tokens.map((t) => ({
      userNotificationId: notificationId,
      deviceToken: t.token,
      payload: {
        title: event.title,
        body: event.body,
        subtitle: event.subtitle,
        unreadCount,
        data: pushData,
      } as unknown as Prisma.InputJsonValue,
      idempotencyKey: `${notificationId}:${t.token}`,
      ...(nextRetryAt ? { nextRetryAt } : {}),
    }));

    const created = await this.prisma.notificationOutbox.createMany({
      data: outboxEntries,
      skipDuplicates: true,
    });

    if (created.count > 0 && isPgOutboxNotifyEnabled()) {
      await this.prisma.$executeRawUnsafe(NOTIFY_SQL.notificationOutboxEnqueued);
    }

    await this.prisma.userNotification.update({
      where: { id: notificationId },
      data: { sentAt: new Date() },
    });

    void this.emailService.sendForNotificationEvent(userId, event).catch((err: unknown) => {
      this.logger.warn(
        `Transactional email failed for user ${userId}: ${err instanceof Error ? err.message : String(err)}`,
      );
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
