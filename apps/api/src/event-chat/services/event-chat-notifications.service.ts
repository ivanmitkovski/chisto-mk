import { Injectable, Logger } from '@nestjs/common';
import { NotificationType } from '../../prisma-client';
import {
  eventChatMessageFallback,
  eventChatSomeoneFallback,
} from '../../common/i18n/event-chat-notification.copy';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationDispatcherService } from '../../notifications/services/notification-dispatcher.service';
import { FeatureFlagsService } from '../../feature-flags/services/feature-flags.service';
import { EventChatPushAggregatorService } from './event-chat-push-aggregator.service';
import { buildEventChatPushPreview } from '../util/event-chat-push-preview';
import type { EventChatMessageRow } from '../util/event-chat-message.select';
import { resolveActorIdentity } from '../../common/projections/public-identity.projection';
import type { AppLocale } from '../../common/i18n/app-locale';

const REPLY_SNIPPET_MAX = 120;

/** Max event participants considered for chat push fan-out (organizer added separately). */
const EVENT_CHAT_PUSH_PARTICIPANT_CAP = 2_000;

/**
 * FCM fan-out for new chat messages (one push per message; optional coalesce v2 flag for rollback).
 */
@Injectable()
export class EventChatNotificationsService {
  private readonly logger = new Logger(EventChatNotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationDispatcher: NotificationDispatcherService,
    private readonly featureFlags: FeatureFlagsService,
    private readonly pushAggregator: EventChatPushAggregatorService,
  ) {}

  async notifyParticipantsDebounced(
    eventId: string,
    senderId: string,
    created: EventChatMessageRow,
    messagePreview: string,
  ): Promise<void> {
    const event = await this.prisma.cleanupEvent.findUnique({
      where: { id: eventId },
      select: { title: true, organizerId: true },
    });
    if (!event) {
      return;
    }

    const participantRows = await this.prisma.eventParticipant.findMany({
      where: { eventId },
      select: { userId: true },
      take: EVENT_CHAT_PUSH_PARTICIPANT_CAP + 1,
    });
    const capped = participantRows.length > EVENT_CHAT_PUSH_PARTICIPANT_CAP;
    const participants = capped
      ? participantRows.slice(0, EVENT_CHAT_PUSH_PARTICIPANT_CAP)
      : participantRows;
    if (capped) {
      this.logger.warn(
        `EVENT_CHAT participant fan-out capped at ${EVENT_CHAT_PUSH_PARTICIPANT_CAP} for event ${eventId}`,
      );
    }
    const recipientIds = new Set<string>();
    for (const p of participants) {
      if (p.userId != null && p.userId !== senderId) {
        recipientIds.add(p.userId);
      }
    }
    if (event.organizerId && event.organizerId !== senderId) {
      recipientIds.add(event.organizerId);
    }

    const mutedRows = await this.prisma.eventChatMute.findMany({
      where: {
        eventId,
        userId: { in: [...recipientIds] },
      },
      select: { userId: true },
    });
    const muted = new Set(mutedRows.map((m) => m.userId));

    const senderIdentity = resolveActorIdentity(created.author, {
      actorUserId: created.authorId,
    });
    const coalesceV2 = await this.featureFlags.isEventChatPushCoalesceV2Enabled();
    const localeBy = await notificationLocalesByUserId(this.prisma, [...recipientIds]);

    for (const recipientId of recipientIds) {
      if (muted.has(recipientId)) {
        continue;
      }
      const locale = localeBy.get(recipientId)!;
      const senderName =
        senderIdentity.displayName ?? eventChatSomeoneFallback(locale);
      const preview = this.snippet(
        messagePreview.trim().length > 0
            ? messagePreview
            : buildEventChatPushPreview(created, '', locale),
        locale,
      );
      if (coalesceV2) {
        this.pushAggregator.enqueue({
          recipientUserId: recipientId,
          recipientLocale: locale,
          eventId,
          eventTitle: event.title,
          senderDisplayName: senderName,
          senderUserId: senderId,
          messagePreview: preview,
          messageId: created.id,
          messageType: created.messageType,
        });
        continue;
      }
      const threadKey = `event-chat:${eventId}:${created.id}`;
      const groupKey = `event-chat:${eventId}`;
      void this.notificationDispatcher
        .dispatchToUser(recipientId, {
          title: event.title,
          body: `${senderName}: ${preview}`,
          type: NotificationType.EVENT_CHAT,
          threadKey,
          groupKey,
          data: {
            eventId,
            messageId: created.id,
            messageCount: 1,
            messagePreview: preview.slice(0, 100),
            messageType: String(created.messageType),
            senderName,
            actorUserId: senderId,
            threadTitle: event.title,
            collapseId: `event-chat-msg:${created.id}`,
          },
        })
        .catch((err: unknown) => {
          this.logger.warn(`EVENT_CHAT dispatch failed for ${recipientId}: ${String(err)}`);
        });
    }
  }

  private snippet(body: string, locale: AppLocale): string {
    const t = body.trim();
    const core =
      t.length <= REPLY_SNIPPET_MAX ? t : `${t.slice(0, REPLY_SNIPPET_MAX)}…`;
    return core.length > 0 ? core : eventChatMessageFallback(locale);
  }
}
