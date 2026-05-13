import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { EventChatSseService } from './event-chat-sse.service';

const TYPING_MIN_INTERVAL_MS = 2500;

@Injectable()
export class EventChatPresenceTypingService {
  private readonly lastTypingAcceptedAt = new Map<string, number>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly sse: EventChatSseService,
  ) {}

  async recordTyping(
    eventId: string,
    user: AuthenticatedUser,
    typing: boolean,
  ): Promise<{ data: { ok: true }; meta: { timestamp: string } }> {
    const key = `${eventId}:${user.userId}`;
    const now = Date.now();
    if (typing) {
      const last = this.lastTypingAcceptedAt.get(key) ?? 0;
      if (now - last < TYPING_MIN_INTERVAL_MS) {
        return { data: { ok: true }, meta: { timestamp: new Date().toISOString() } };
      }
      this.lastTypingAcceptedAt.set(key, now);
    } else {
      this.lastTypingAcceptedAt.delete(key);
    }

    const u = await this.prisma.user.findUnique({
      where: { id: user.userId },
      select: { firstName: true, lastName: true },
    });
    const displayName = u ? `${u.firstName} ${u.lastName}`.trim() : '';

    this.sse.emitEvent({
      streamEventId: randomUUID(),
      eventId,
      type: 'typing_update',
      persistInReplay: false,
      userId: user.userId,
      displayName,
      typing,
    });

    return { data: { ok: true }, meta: { timestamp: new Date().toISOString() } };
  }
}
