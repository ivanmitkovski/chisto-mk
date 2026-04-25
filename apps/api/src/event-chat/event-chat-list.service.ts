import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { EventChatMessageResponseDto } from './dto/event-chat-message-response.dto';
import type { ListEventChatQueryDto } from './dto/list-event-chat-query.dto';
import type { SearchEventChatQueryDto } from './dto/search-event-chat-query.dto';
import { EVENT_CHAT_MESSAGE_SELECT } from './event-chat-message.select';
import { EventChatTelemetryService } from './event-chat-telemetry.service';
import { EventChatMessageDtoService } from './event-chat-message-dto.service';
import { MAX_PINNED_PER_EVENT } from './event-chat.constants';

@Injectable()
export class EventChatListService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly telemetry: EventChatTelemetryService,
    private readonly dto: EventChatMessageDtoService,
  ) {}

  async listMessages(
    eventId: string,
    user: AuthenticatedUser,
    query: ListEventChatQueryDto,
  ): Promise<{
    data: EventChatMessageResponseDto[];
    meta: { timestamp: string; hasMore: boolean; nextCursor: string | null };
  }> {
    const t0 = Date.now();
    const limit = query.limit;
    const where: Prisma.EventChatMessageWhereInput = { eventId };

    if (query.cursor?.trim()) {
      const ref = await this.prisma.eventChatMessage.findFirst({
        where: { id: query.cursor.trim(), eventId },
        select: { id: true, createdAt: true },
      });
      if (!ref) {
        throw new BadRequestException({
          code: 'INVALID_CHAT_CURSOR',
          message: 'Invalid cursor',
        });
      }
      where.OR = [
        { createdAt: { lt: ref.createdAt } },
        { AND: [{ createdAt: ref.createdAt }, { id: { lt: ref.id } }] },
      ];
    }

    const take = limit + 1;
    const rows = await this.prisma.eventChatMessage.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take,
      select: EVENT_CHAT_MESSAGE_SELECT,
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore && page.length > 0 ? page[page.length - 1]!.id : null;

    const data = await Promise.all(page.map((r) => this.dto.finalizeMessageDto(r, user.userId)));
    this.telemetry.emitSpan('event_chat.list_messages', {
      duration_ms: Date.now() - t0,
      hasMore,
      limit,
    });
    return {
      data,
      meta: {
        timestamp: new Date().toISOString(),
        hasMore,
        nextCursor,
      },
    };
  }

  async searchMessages(
    eventId: string,
    user: AuthenticatedUser,
    query: SearchEventChatQueryDto,
  ): Promise<{
    data: EventChatMessageResponseDto[];
    meta: { timestamp: string; hasMore: boolean; nextCursor: string | null };
  }> {
    const limit = query.limit;
    const q = query.q.trim();
    // Encrypted bodies are ciphertext; search only plaintext rows (see EVENT_CHAT_BODY_INVALID for send path).
    const where: Prisma.EventChatMessageWhereInput = {
      eventId,
      deletedAt: null,
      bodyEncrypted: false,
      body: { contains: q, mode: 'insensitive' },
    };

    if (query.cursor?.trim()) {
      const ref = await this.prisma.eventChatMessage.findFirst({
        where: { id: query.cursor.trim(), eventId },
        select: { id: true, createdAt: true },
      });
      if (!ref) {
        throw new BadRequestException({
          code: 'INVALID_CHAT_CURSOR',
          message: 'Invalid cursor',
        });
      }
      where.AND = [
        {
          OR: [
            { createdAt: { lt: ref.createdAt } },
            { AND: [{ createdAt: ref.createdAt }, { id: { lt: ref.id } }] },
          ],
        },
      ];
    }

    const take = limit + 1;
    const rows = await this.prisma.eventChatMessage.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take,
      select: EVENT_CHAT_MESSAGE_SELECT,
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore && page.length > 0 ? page[page.length - 1]!.id : null;

    const data = await Promise.all(page.map((r) => this.dto.finalizeMessageDto(r, user.userId)));
    return {
      data,
      meta: {
        timestamp: new Date().toISOString(),
        hasMore,
        nextCursor,
      },
    };
  }

  async listPinnedMessages(
    eventId: string,
    user: AuthenticatedUser,
  ): Promise<{
    data: EventChatMessageResponseDto[];
    meta: { timestamp: string };
  }> {
    const rows = await this.prisma.eventChatMessage.findMany({
      where: {
        eventId,
        isPinned: true,
        deletedAt: null,
      },
      orderBy: [{ pinnedAt: 'desc' }, { id: 'desc' }],
      take: MAX_PINNED_PER_EVENT,
      select: EVENT_CHAT_MESSAGE_SELECT,
    });
    const data = await Promise.all(rows.map((r) => this.dto.finalizeMessageDto(r, user.userId)));
    return {
      data,
      meta: { timestamp: new Date().toISOString() },
    };
  }
}
