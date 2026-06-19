import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { isPgOutboxNotifyEnabled, NOTIFY_SQL } from '../../common/pg/outbox-pg-notify';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { ObservabilityStore } from '../../observability/observability.store';
import { NotificationWriterService } from './notification-writer.service';
import { DeviceTokenService } from './device-token.service';
import { FcmPushService } from './fcm-push.service';
import { buildFcmDataPayload } from '../util/notification-push-data';
import type { NotificationEvent } from '../types/notification-event.types';
import { EmailDeliveryOutboxService } from '../../email/services/email-delivery-outbox.service';
import { NotificationsRoomEmitterService } from './notifications-room-emitter.service';
import { FeatureFlagsService } from '../../feature-flags/services/feature-flags.service';
import { resolveInterruptionLevel } from '../util/fcm-apns-payload';
import { computeQuietHoursDeferral } from '../util/notification-quiet-hours';
import { shouldDeferVisiblePush } from '../util/notification-push-rate-limit';

export type { NotificationEvent } from '../types/notification-event.types';

@Injectable()
export class NotificationDispatcherService {
  private readonly logger = new Logger(NotificationDispatcherService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly writer: NotificationWriterService,
    private readonly deviceTokens: DeviceTokenService,
    private readonly fcm: FcmPushService,
    private readonly emailOutbox: EmailDeliveryOutboxService,
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
      ObservabilityStore.recordPushDispatchSkippedWriterNull();
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

    if (!this.fcm.isEnabled() || !this.fcm.isReady()) {
      ObservabilityStore.recordPushDispatchSkippedFcmNotReady();
      this.logger.warn(
        `push skipped (enabled=${this.fcm.isEnabled()} ready=${this.fcm.isReady()}) user=${userId} notification=${notificationId}`,
      );
      await this.emailOutbox.enqueue(userId, notificationId, event);
      return;
    }

    const tokens = await this.deviceTokens.getActiveTokensForUser(userId);
    if (tokens.length === 0) {
      ObservabilityStore.recordPushDispatchSkippedNoTokens();
      this.logger.warn(
        `push skipped (no active device tokens) user=${userId} notification=${notificationId}`,
      );
      await this.emailOutbox.enqueue(userId, notificationId, event);
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
        platform: t.platform,
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

    await this.emailOutbox.enqueue(userId, notificationId, event);
  }
}
