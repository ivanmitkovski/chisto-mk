import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EventChatMessageType, NotificationType } from '../../prisma-client';
import { NotificationDispatcherService } from '../../notifications/services/notification-dispatcher.service';
import { buildEventChatPushPreview } from '../util/event-chat-push-preview';

const DEFAULT_FLUSH_MS = 2_500;

type PendingChatPush = {
  recipientUserId: string;
  recipientLocale: import('../../common/i18n/app-locale').AppLocale;
  eventId: string;
  eventTitle: string;
  senderDisplayName: string;
  senderUserId: string;
  latestPreview: string;
  latestMessageType: EventChatMessageType;
  latestMessageId: string;
  messageCount: number;
  flushTimer: ReturnType<typeof setTimeout> | null;
};

/**
 * Coalesces rapid event-chat messages into one updating push per (event, recipient).
 */
@Injectable()
export class EventChatPushAggregatorService {
  private readonly logger = new Logger(EventChatPushAggregatorService.name);
  private readonly pending = new Map<string, PendingChatPush>();
  private readonly flushMs: number;

  constructor(
    private readonly configService: ConfigService,
    private readonly notificationDispatcher: NotificationDispatcherService,
  ) {
    const raw = this.configService.get<string>('EVENT_CHAT_PUSH_FLUSH_MS', String(DEFAULT_FLUSH_MS));
    const parsed = Number(raw);
    this.flushMs = Number.isFinite(parsed) && parsed >= 500 ? parsed : DEFAULT_FLUSH_MS;
  }

  enqueue(input: {
    recipientUserId: string;
    recipientLocale: import('../../common/i18n/app-locale').AppLocale;
    eventId: string;
    eventTitle: string;
    senderDisplayName: string;
    senderUserId: string;
    messagePreview: string;
    messageId: string;
    messageType: EventChatMessageType;
  }): void {
    const key = `${input.eventId}:${input.recipientUserId}`;
    const existing = this.pending.get(key);
    if (existing != null) {
      existing.messageCount += 1;
      existing.latestPreview = input.messagePreview;
      existing.latestMessageType = input.messageType;
      existing.latestMessageId = input.messageId;
      existing.senderDisplayName = input.senderDisplayName;
      existing.senderUserId = input.senderUserId;
      existing.eventTitle = input.eventTitle;
      return;
    }

    this.pending.set(key, {
      recipientUserId: input.recipientUserId,
      recipientLocale: input.recipientLocale,
      eventId: input.eventId,
      eventTitle: input.eventTitle,
      senderDisplayName: input.senderDisplayName,
      senderUserId: input.senderUserId,
      latestPreview: input.messagePreview,
      latestMessageType: input.messageType,
      latestMessageId: input.messageId,
      messageCount: 1,
      flushTimer: null,
    });

    const batch = this.pending.get(key)!;
    batch.flushTimer = setTimeout(() => {
      void this.flush(key);
    }, this.flushMs);
  }

  private async flush(key: string): Promise<void> {
    const batch = this.pending.get(key);
    if (batch == null) {
      return;
    }
    this.pending.delete(key);
    if (batch.flushTimer != null) {
      clearTimeout(batch.flushTimer);
      batch.flushTimer = null;
    }

    const groupKey = `event-chat:${batch.eventId}`;
    const threadKey = `${groupKey}:${batch.latestMessageId}`;
    const preview =
      batch.latestPreview.trim().length > 0
        ? batch.latestPreview
        : buildEventChatPushPreview(
            {
              messageType: batch.latestMessageType,
              locationLabel: null,
              attachments: [],
              body: '',
            },
            '',
            batch.recipientLocale,
          );
    const senderName = batch.senderDisplayName;
    const body =
      batch.messageCount === 1
        ? `${senderName}: ${preview}`
        : `${senderName}: ${preview} (+${batch.messageCount - 1})`;

    try {
      await this.notificationDispatcher.dispatchToUser(batch.recipientUserId, {
        title: batch.eventTitle,
        body,
        type: NotificationType.EVENT_CHAT,
        threadKey,
        groupKey,
        data: {
          eventId: batch.eventId,
          messageId: batch.latestMessageId,
          messageCount: batch.messageCount,
          messagePreview: preview.slice(0, 100),
          messageType: String(batch.latestMessageType),
          senderName,
          actorUserId: batch.senderUserId,
          threadTitle: batch.eventTitle,
          collapseId: `event-chat-msg:${batch.latestMessageId}`,
        },
      });
    } catch (err: unknown) {
      this.logger.warn(
        `EVENT_CHAT coalesced dispatch failed for ${batch.recipientUserId}: ${String(err)}`,
      );
    }
  }

  /** @internal test hook */
  pendingSizeForTests(): number {
    return this.pending.size;
  }
}
