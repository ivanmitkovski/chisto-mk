import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { PatchEventChatReadDto } from './dto/patch-event-chat-read.dto';
import { EventChatSseService } from './event-chat-sse.service';

/** Safety cap on joiners scanned when building read-cursor roster for organizers. */
const READ_CURSORS_PARTICIPANT_CAP = 2000;

@Injectable()
export class EventChatPresenceReadStateService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sse: EventChatSseService,
  ) {}

  async patchReadCursor(
    eventId: string,
    user: AuthenticatedUser,
    dto: PatchEventChatReadDto,
  ): Promise<{ data: { ok: true }; meta: { timestamp: string } }> {
    const lastRead = dto.lastReadMessageId?.trim() || null;
    if (lastRead) {
      const exists = await this.prisma.eventChatMessage.findFirst({
        where: { id: lastRead, eventId },
        select: { id: true, createdAt: true },
      });
      if (!exists) {
        throw new BadRequestException({
          code: 'EVENT_CHAT_READ_MESSAGE_NOT_FOUND',
          message: 'Message not found in this event',
        });
      }

      const current = await this.prisma.eventChatReadCursor.findUnique({
        where: { eventId_userId: { eventId, userId: user.userId } },
        select: { lastReadMessageId: true },
      });
      if (current?.lastReadMessageId) {
        const prevMsg = await this.prisma.eventChatMessage.findFirst({
          where: { id: current.lastReadMessageId, eventId },
          select: { createdAt: true, id: true },
        });
        if (prevMsg) {
          const prevT = prevMsg.createdAt.getTime();
          const nextT = exists.createdAt.getTime();
          if (nextT < prevT || (nextT === prevT && exists.id < prevMsg.id)) {
            throw new BadRequestException({
              code: 'EVENT_CHAT_READ_CURSOR_STALE',
              message: 'Read cursor can only move forward to newer messages',
            });
          }
        }
      }
    }

    await this.prisma.eventChatReadCursor.upsert({
      where: {
        eventId_userId: { eventId, userId: user.userId },
      },
      create: {
        eventId,
        userId: user.userId,
        lastReadMessageId: lastRead,
      },
      update: {
        lastReadMessageId: lastRead,
      },
    });

    let lastReadMessageCreatedAt: string | null = null;
    if (lastRead) {
      const refMsg = await this.prisma.eventChatMessage.findFirst({
        where: { id: lastRead, eventId },
        select: { createdAt: true },
      });
      lastReadMessageCreatedAt = refMsg?.createdAt.toISOString() ?? null;
    }

    const reader = await this.prisma.user.findUnique({
      where: { id: user.userId },
      select: { firstName: true, lastName: true },
    });
    const displayName = reader ? `${reader.firstName} ${reader.lastName}`.trim() : '';

    this.sse.emitEvent({
      streamEventId: randomUUID(),
      eventId,
      type: 'read_cursor_updated',
      persistInReplay: false,
      userId: user.userId,
      displayName,
      lastReadMessageId: lastRead,
      lastReadMessageCreatedAt,
    });

    return { data: { ok: true }, meta: { timestamp: new Date().toISOString() } };
  }

  async listReadCursors(eventId: string): Promise<{
    data: {
      cursors: Array<{
        userId: string;
        displayName: string;
        lastReadMessageId: string | null;
        lastReadMessageCreatedAt: string | null;
      }>;
    };
    meta: { timestamp: string };
  }> {
    const event = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId },
      select: { organizerId: true },
    });
    if (!event) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    const rows = await this.prisma.eventParticipant.findMany({
      where: { eventId },
      orderBy: { joinedAt: 'asc' },
      take: READ_CURSORS_PARTICIPANT_CAP,
      select: {
        user: { select: { id: true, firstName: true, lastName: true } },
      },
    });

    const ordered: { id: string; displayName: string }[] = [];
    const seen = new Set<string>();

    if (event.organizerId) {
      const org = await this.prisma.user.findUnique({
        where: { id: event.organizerId },
        select: { id: true, firstName: true, lastName: true },
      });
      if (org) {
        ordered.push({
          id: org.id,
          displayName: `${org.firstName} ${org.lastName}`.trim(),
        });
        seen.add(org.id);
      }
    }

    for (const r of rows) {
      if (seen.has(r.user.id)) {
        continue;
      }
      ordered.push({
        id: r.user.id,
        displayName: `${r.user.firstName} ${r.user.lastName}`.trim(),
      });
      seen.add(r.user.id);
    }

    const ids = ordered.map((o) => o.id);
    if (ids.length === 0) {
      return {
        data: { cursors: [] },
        meta: { timestamp: new Date().toISOString() },
      };
    }

    const cursorRows = await this.prisma.eventChatReadCursor.findMany({
      where: { eventId, userId: { in: ids } },
      select: { userId: true, lastReadMessageId: true },
    });
    const byUser = new Map(cursorRows.map((c) => [c.userId, c]));

    const messageIds = [
      ...new Set(
        cursorRows
          .map((c) => c.lastReadMessageId)
          .filter((id): id is string => id != null && id !== ''),
      ),
    ];
    const msgRows =
      messageIds.length > 0
        ? await this.prisma.eventChatMessage.findMany({
            where: { eventId, id: { in: messageIds } },
            select: { id: true, createdAt: true },
          })
        : [];
    const createdByMsgId = new Map(msgRows.map((m) => [m.id, m.createdAt.toISOString()]));

    const cursors = ordered.map((u) => {
      const cur = byUser.get(u.id);
      const lastId = cur?.lastReadMessageId ?? null;
      const lastCreated = lastId ? (createdByMsgId.get(lastId) ?? null) : null;
      return {
        userId: u.id,
        displayName: u.displayName,
        lastReadMessageId: lastId,
        lastReadMessageCreatedAt: lastCreated,
      };
    });

    return {
      data: { cursors },
      meta: { timestamp: new Date().toISOString() },
    };
  }

  async unreadCount(
    eventId: string,
    user: AuthenticatedUser,
  ): Promise<{ data: { count: number }; meta: { timestamp: string } }> {
    const cursor = await this.prisma.eventChatReadCursor.findUnique({
      where: {
        eventId_userId: { eventId, userId: user.userId },
      },
      select: { lastReadMessageId: true },
    });

    const base: Prisma.EventChatMessageWhereInput = {
      eventId,
      deletedAt: null,
      authorId: { not: user.userId },
    };

    let where: Prisma.EventChatMessageWhereInput = base;
    if (cursor?.lastReadMessageId) {
      const ref = await this.prisma.eventChatMessage.findFirst({
        where: { id: cursor.lastReadMessageId, eventId },
        select: { id: true, createdAt: true },
      });
      if (ref) {
        where = {
          AND: [
            base,
            {
              OR: [
                { createdAt: { gt: ref.createdAt } },
                { AND: [{ createdAt: ref.createdAt }, { id: { gt: ref.id } }] },
              ],
            },
          ],
        };
      }
    }

    const count = await this.prisma.eventChatMessage.count({ where });
    return {
      data: { count },
      meta: { timestamp: new Date().toISOString() },
    };
  }
}
