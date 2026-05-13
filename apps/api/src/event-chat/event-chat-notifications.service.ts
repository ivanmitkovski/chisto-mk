import { Injectable, Logger } from '@nestjs/common';
import { NotificationType } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationDispatcherService } from '../notifications/notification-dispatcher.service';
import type { EventChatMessageRow } from './event-chat-message.select';

const CHAT_PUSH_DEBOUNCE_MS = 30_000;
const REPLY_SNIPPET_MAX = 120;

/**
 * FCM fan-out for new chat messages (debounced per recipient per event).
 * Chat notification side-effects (kept separate from list/presence/mutation services).
 */
@Injectable()
export class EventChatNotificationsService {
  private readonly logger = new Logger(EventChatNotificationsService.name);
  private readonly lastChatPushAt = new Map<string, number>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationDispatcher: NotificationDispatcherService,
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

    const participants = await this.prisma.eventParticipant.findMany({
      where: { eventId },
      select: { userId: true },
      take: 2_000,
    });
    const recipientIds = new Set<string>();
    for (const p of participants) {
      if (p.userId !== senderId) {
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

    const preview = this.snippet(messagePreview);
    const senderName = `${created.author.firstName} ${created.author.lastName}`.trim();
    const now = Date.now();

    for (const recipientId of recipientIds) {
      if (muted.has(recipientId)) {
        continue;
      }
      const key = `${eventId}:${recipientId}`;
      const last = this.lastChatPushAt.get(key) ?? 0;
      if (now - last < CHAT_PUSH_DEBOUNCE_MS) {
        continue;
      }
      this.lastChatPushAt.set(key, now);

      void this.notificationDispatcher
        .dispatchToUser(recipientId, {
          title: event.title,
          body: `${senderName}: ${preview}`,
          type: NotificationType.EVENT_CHAT,
          threadKey: `event-chat:${eventId}`,
          groupKey: `event-chat:${eventId}`,
          data: {
            eventId,
            messageId: created.id,
            senderName,
            messagePreview: preview.slice(0, 100),
            threadTitle: event.title,
          },
        })
        .catch((err: unknown) => {
          this.logger.warn(`EVENT_CHAT dispatch failed for ${recipientId}: ${String(err)}`);
        });
    }
  }

  private snippet(body: string): string {
    const t = body.trim();
    if (t.length <= REPLY_SNIPPET_MAX) {
      return t;
    }
    return `${t.slice(0, REPLY_SNIPPET_MAX)}…`;
  }
}
