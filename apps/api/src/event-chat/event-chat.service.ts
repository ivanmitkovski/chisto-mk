import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  EventChatMessageType,
  NotificationType,
  Prisma,
} from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { NotificationDispatcherService } from '../notifications/notification-dispatcher.service';
import type { EventChatMessageResponseDto } from './dto/event-chat-message-response.dto';
import type { EditEventChatMessageDto } from './dto/edit-event-chat-message.dto';
import type { ListEventChatQueryDto } from './dto/list-event-chat-query.dto';
import type { MuteChatDto } from './dto/mute-chat.dto';
import type { PatchEventChatReadDto } from './dto/patch-event-chat-read.dto';
import type { PinEventChatMessageDto } from './dto/pin-event-chat-message.dto';
import type { SearchEventChatQueryDto } from './dto/search-event-chat-query.dto';
import type { SendEventChatMessageDto } from './dto/send-event-chat-message.dto';
import { ChatEncryptionService } from './chat-encryption.service';
import {
  EVENT_CHAT_MESSAGE_SELECT,
  type EventChatMessageRow,
} from './event-chat-message.select';
import { EventChatSseService } from './event-chat-sse.service';
import { EventChatTelemetryService } from './event-chat-telemetry.service';
import { EventChatUploadService } from './event-chat-upload.service';

const CHAT_PUSH_DEBOUNCE_MS = 30_000;
const TYPING_MIN_INTERVAL_MS = 2500;
const REPLY_SNIPPET_MAX = 120;
const MAX_PINNED_PER_EVENT = 10;

@Injectable()
export class EventChatService {
  private readonly logger = new Logger(EventChatService.name);
  private readonly lastChatPushAt = new Map<string, number>();
  private readonly lastTypingAcceptedAt = new Map<string, number>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly sse: EventChatSseService,
    private readonly notificationDispatcher: NotificationDispatcherService,
    private readonly encryption: ChatEncryptionService,
    private readonly chatUpload: EventChatUploadService,
    private readonly uploads: ReportsUploadService,
    private readonly telemetry: EventChatTelemetryService,
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

    const data = await Promise.all(
      page.map((r) => this.finalizeMessageDto(r, user.userId)),
    );
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
    const where: Prisma.EventChatMessageWhereInput = {
      eventId,
      deletedAt: null,
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

    const data = await Promise.all(
      page.map((r) => this.finalizeMessageDto(r, user.userId)),
    );
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
      select: EVENT_CHAT_MESSAGE_SELECT,
    });
    const data = await Promise.all(
      rows.map((r) => this.finalizeMessageDto(r, user.userId)),
    );
    return {
      data,
      meta: { timestamp: new Date().toISOString() },
    };
  }

  async sendMessage(
    eventId: string,
    user: AuthenticatedUser,
    dto: SendEventChatMessageDto,
  ): Promise<{ data: EventChatMessageResponseDto; meta: { timestamp: string } }> {
    const body = this.normalizeBody(dto.body);
    const hasAttachments = (dto.attachments?.length ?? 0) > 0;
    const hasLocation = dto.location != null;
    if (!hasAttachments && !hasLocation) {
      if (body.length < 1 || body.length > 2000) {
        throw new BadRequestException({
          code: 'EVENT_CHAT_BODY_INVALID',
          message: 'Message must be between 1 and 2000 characters',
        });
      }
    } else if (body.length > 2000) {
      throw new BadRequestException({
        code: 'EVENT_CHAT_BODY_INVALID',
        message: 'Message must be at most 2000 characters',
      });
    }

    let replyToId: string | null = null;
    if (dto.replyToId?.trim()) {
      const parent = await this.prisma.eventChatMessage.findFirst({
        where: { id: dto.replyToId.trim(), eventId },
        select: { id: true },
      });
      if (!parent) {
        throw new BadRequestException({
          code: 'EVENT_CHAT_REPLY_NOT_FOUND',
          message: 'Reply target not found',
        });
      }
      replyToId = parent.id;
    }

    let messageType: EventChatMessageType = EventChatMessageType.TEXT;
    let locationLat: number | null = null;
    let locationLng: number | null = null;
    let locationLabel: string | null = null;

    if (dto.location) {
      messageType = EventChatMessageType.LOCATION;
      locationLat = dto.location.lat;
      locationLng = dto.location.lng;
      locationLabel = dto.location.label ?? null;
    } else if (dto.attachments?.length) {
      const mime = dto.attachments[0]!.mimeType.toLowerCase();
      if (mime.startsWith('video/')) {
        messageType = EventChatMessageType.VIDEO;
      } else if (mime.startsWith('audio/')) {
        messageType = EventChatMessageType.AUDIO;
      } else if (mime.startsWith('application/') || mime.startsWith('text/')) {
        messageType = EventChatMessageType.FILE;
      } else {
        messageType = EventChatMessageType.IMAGE;
      }
    }

    const attachData = (dto.attachments ?? []).map((a) => ({
      url: a.url,
      mimeType: a.mimeType,
      fileName: a.fileName,
      sizeBytes: a.sizeBytes,
      width: a.width ?? null,
      height: a.height ?? null,
      duration: a.duration ?? null,
      thumbnailUrl: a.thumbnailUrl ?? null,
    }));

    const sendStarted = Date.now();
    const clientId = dto.clientMessageId?.trim() ?? '';
    if (clientId) {
      const existing = await this.prisma.eventChatMessage.findFirst({
        where: { eventId, clientMessageId: clientId },
        select: EVENT_CHAT_MESSAGE_SELECT,
      });
      if (existing) {
        if (existing.authorId !== user.userId) {
          throw new ForbiddenException({
            code: 'EVENT_CHAT_CLIENT_ID_CONFLICT',
            message: 'Client message id already used',
          });
        }
        return {
          data: await this.finalizeMessageDto(existing, user.userId),
          meta: { timestamp: new Date().toISOString() },
        };
      }
    }

    const shouldEncrypt = this.encryption.enabled;
    const storedBody = shouldEncrypt ? this.encryption.encrypt(body) : body;

    let created: EventChatMessageRow;
    try {
      created = await this.prisma.eventChatMessage.create({
        data: {
          eventId,
          authorId: user.userId,
          body: storedBody,
          bodyEncrypted: shouldEncrypt,
          replyToId,
          messageType,
          locationLat,
          locationLng,
          locationLabel,
          ...(clientId ? { clientMessageId: clientId } : {}),
          ...(attachData.length
            ? { attachments: { createMany: { data: attachData } } }
            : {}),
        },
        select: EVENT_CHAT_MESSAGE_SELECT,
      });
    } catch (e) {
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002' &&
        clientId
      ) {
        const retry = await this.prisma.eventChatMessage.findFirst({
          where: { eventId, clientMessageId: clientId },
          select: EVENT_CHAT_MESSAGE_SELECT,
        });
        if (retry && retry.authorId === user.userId) {
          return {
            data: await this.finalizeMessageDto(retry, user.userId),
            meta: { timestamp: new Date().toISOString() },
          };
        }
      }
      this.telemetry.emitMetric({
        name: 'event_chat.message.send_failed',
        ok: false,
        reason: e instanceof Prisma.PrismaClientKnownRequestError ? e.code : 'unknown',
      });
      throw e;
    }

    const streamEventId = randomUUID();
    const streamPayload = await this.finalizeMessageDto(created, '');
    this.sse.emitEvent({
      streamEventId,
      eventId,
      type: 'message_created',
      message: streamPayload as unknown as Record<string, unknown>,
    });

    void this.notifyParticipantsDebounced(eventId, user.userId, created).catch((err: unknown) => {
      this.logger.warn(`Event chat push scheduling failed: ${String(err)}`);
    });

    this.logger.log(
      `eventChat.sendMessage eventId=${eventId} messageId=${created.id} userId=${user.userId} type=${messageType}`,
    );

    this.telemetry.emitMetric({
      name: 'event_chat.message.sent',
      ok: true,
      duration_ms: Date.now() - sendStarted,
    });
    this.telemetry.emitSpan('event_chat.send_message', {
      ok: true,
      duration_ms: Date.now() - sendStarted,
    });

    return {
      data: await this.finalizeMessageDto(created, user.userId),
      meta: { timestamp: new Date().toISOString() },
    };
  }

  /**
   * Creates a system message (join/leave/event update). Emits SSE only; no push notifications.
   */
  async createSystemMessage(params: {
    eventId: string;
    authorId: string;
    body: string;
    systemPayload: Prisma.InputJsonValue;
  }): Promise<void> {
    const body = this.normalizeBody(params.body);
    if (body.length < 1 || body.length > 2000) {
      this.logger.warn('createSystemMessage: body invalid, skipping');
      return;
    }
    const created = await this.prisma.eventChatMessage.create({
      data: {
        eventId: params.eventId,
        authorId: params.authorId,
        body,
        messageType: EventChatMessageType.SYSTEM,
        systemPayload: params.systemPayload,
      },
      select: EVENT_CHAT_MESSAGE_SELECT,
    });
    const streamEventId = randomUUID();
    const streamPayload = await this.finalizeMessageDto(created, '');
    this.sse.emitEvent({
      streamEventId,
      eventId: params.eventId,
      type: 'message_created',
      message: streamPayload as unknown as Record<string, unknown>,
    });
  }

  async editMessage(
    eventId: string,
    messageId: string,
    user: AuthenticatedUser,
    dto: EditEventChatMessageDto,
  ): Promise<{ data: EventChatMessageResponseDto; meta: { timestamp: string } }> {
    const body = this.normalizeBody(dto.body);
    if (body.length < 1 || body.length > 2000) {
      throw new BadRequestException({
        code: 'EVENT_CHAT_BODY_INVALID',
        message: 'Message must be between 1 and 2000 characters',
      });
    }

    const msg = await this.prisma.eventChatMessage.findFirst({
      where: { id: messageId, eventId },
      select: EVENT_CHAT_MESSAGE_SELECT,
    });
    if (!msg) {
      throw new NotFoundException({
        code: 'EVENT_CHAT_MESSAGE_NOT_FOUND',
        message: 'Message not found',
      });
    }
    if (msg.deletedAt != null) {
      throw new BadRequestException({
        code: 'EVENT_CHAT_EDIT_DELETED',
        message: 'Cannot edit a removed message',
      });
    }
    if (msg.messageType !== EventChatMessageType.TEXT) {
      throw new BadRequestException({
        code: 'EVENT_CHAT_EDIT_FORBIDDEN',
        message: 'This message cannot be edited',
      });
    }
    if (msg.authorId !== user.userId) {
      throw new ForbiddenException({
        code: 'EVENT_CHAT_EDIT_FORBIDDEN',
        message: 'You can only edit your own messages',
      });
    }

    const updated = await this.prisma.eventChatMessage.update({
      where: { id: messageId },
      data: { body, editedAt: new Date() },
      select: EVENT_CHAT_MESSAGE_SELECT,
    });

    const streamEventId = randomUUID();
    const streamPayload = await this.finalizeMessageDto(updated, '');
    this.sse.emitEvent({
      streamEventId,
      eventId,
      type: 'message_edited',
      message: streamPayload as unknown as Record<string, unknown>,
    });

    this.telemetry.emitAudit('message_edited', {
      actorId: user.userId,
      messageId,
      eventId,
    });

    return {
      data: await this.finalizeMessageDto(updated, user.userId),
      meta: { timestamp: new Date().toISOString() },
    };
  }

  async setMessagePin(
    eventId: string,
    messageId: string,
    user: AuthenticatedUser,
    dto: PinEventChatMessageDto,
  ): Promise<{ data: EventChatMessageResponseDto; meta: { timestamp: string } }> {
    const msg = await this.prisma.eventChatMessage.findFirst({
      where: { id: messageId, eventId },
      include: {
        event: { select: { organizerId: true } },
      },
    });
    if (!msg) {
      throw new NotFoundException({
        code: 'EVENT_CHAT_MESSAGE_NOT_FOUND',
        message: 'Message not found',
      });
    }
    if (msg.event.organizerId !== user.userId) {
      throw new ForbiddenException({
        code: 'EVENT_CHAT_PIN_FORBIDDEN',
        message: 'Only the organizer can pin messages',
      });
    }
    if (msg.deletedAt != null) {
      throw new BadRequestException({
        code: 'EVENT_CHAT_PIN_DELETED',
        message: 'Cannot pin a removed message',
      });
    }
    if (msg.messageType !== EventChatMessageType.TEXT) {
      throw new BadRequestException({
        code: 'EVENT_CHAT_PIN_TYPE',
        message: 'Only text messages can be pinned',
      });
    }

    if (dto.pinned) {
      if (!msg.isPinned) {
        const pinnedCount = await this.prisma.eventChatMessage.count({
          where: { eventId, isPinned: true },
        });
        if (pinnedCount >= MAX_PINNED_PER_EVENT) {
          throw new BadRequestException({
            code: 'EVENT_CHAT_PIN_LIMIT',
            message: 'Maximum pinned messages reached for this event',
          });
        }
      }
      const updated = await this.prisma.eventChatMessage.update({
        where: { id: messageId },
        data: {
          isPinned: true,
          pinnedAt: new Date(),
          pinnedById: user.userId,
        },
        select: EVENT_CHAT_MESSAGE_SELECT,
      });
      const streamEventId = randomUUID();
      const streamPayload = await this.finalizeMessageDto(updated, '');
      this.sse.emitEvent({
        streamEventId,
        eventId,
        type: 'message_pinned',
        message: streamPayload as unknown as Record<string, unknown>,
      });
      this.telemetry.emitAudit('message_pinned', {
        actorId: user.userId,
        messageId,
        eventId,
      });
      return {
        data: await this.finalizeMessageDto(updated, user.userId),
        meta: { timestamp: new Date().toISOString() },
      };
    }

    const updated = await this.prisma.eventChatMessage.update({
      where: { id: messageId },
      data: {
        isPinned: false,
        pinnedAt: null,
        pinnedById: null,
      },
      select: EVENT_CHAT_MESSAGE_SELECT,
    });
    const streamEventId = randomUUID();
    const streamUnpin = await this.finalizeMessageDto(updated, '');
    this.sse.emitEvent({
      streamEventId,
      eventId,
      type: 'message_unpinned',
      message: streamUnpin as unknown as Record<string, unknown>,
    });
    this.telemetry.emitAudit('message_unpinned', {
      actorId: user.userId,
      messageId,
      eventId,
    });
    return {
      data: await this.finalizeMessageDto(updated, user.userId),
      meta: { timestamp: new Date().toISOString() },
    };
  }

  async getMuteStatus(
    eventId: string,
    user: AuthenticatedUser,
  ): Promise<{ data: { muted: boolean }; meta: { timestamp: string } }> {
    const row = await this.prisma.eventChatMute.findUnique({
      where: {
        eventId_userId: { eventId, userId: user.userId },
      },
      select: { id: true },
    });
    return {
      data: { muted: row != null },
      meta: { timestamp: new Date().toISOString() },
    };
  }

  async setMuteStatus(
    eventId: string,
    user: AuthenticatedUser,
    dto: MuteChatDto,
  ): Promise<{ data: { ok: true; muted: boolean }; meta: { timestamp: string } }> {
    if (dto.muted) {
      await this.prisma.eventChatMute.upsert({
        where: {
          eventId_userId: { eventId, userId: user.userId },
        },
        create: { eventId, userId: user.userId },
        update: {},
      });
    } else {
      await this.prisma.eventChatMute.deleteMany({
        where: { eventId, userId: user.userId },
      });
    }
    return {
      data: { ok: true, muted: dto.muted },
      meta: { timestamp: new Date().toISOString() },
    };
  }

  async listParticipants(eventId: string): Promise<{
    data: {
      count: number;
      participants: { id: string; displayName: string; avatarUrl: string | null }[];
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
      select: {
        user: {
          select: { id: true, firstName: true, lastName: true, avatarObjectKey: true },
        },
      },
    });

    const participants: { id: string; displayName: string; avatarUrl: string | null }[] = [];
    const seen = new Set<string>();

    if (event.organizerId) {
      const org = await this.prisma.user.findUnique({
        where: { id: event.organizerId },
        select: {
          id: true,
          firstName: true,
          lastName: true,
          avatarObjectKey: true,
        },
      });
      if (org) {
        participants.push({
          id: org.id,
          displayName: `${org.firstName} ${org.lastName}`.trim(),
          avatarUrl: await this.uploads.signPrivateObjectKey(org.avatarObjectKey),
        });
        seen.add(org.id);
      }
    }

    for (const r of rows) {
      if (seen.has(r.user.id)) {
        continue;
      }
      if (participants.length >= 50) {
        break;
      }
      participants.push({
        id: r.user.id,
        displayName: `${r.user.firstName} ${r.user.lastName}`.trim(),
        avatarUrl: await this.uploads.signPrivateObjectKey(r.user.avatarObjectKey),
      });
      seen.add(r.user.id);
    }

    const participantUserIds = await this.prisma.eventParticipant.findMany({
      where: { eventId },
      select: { userId: true },
    });
    const unique = new Set<string>(participantUserIds.map((p) => p.userId));
    if (event.organizerId) {
      unique.add(event.organizerId);
    }
    const count = unique.size;

    return {
      data: { count, participants },
      meta: { timestamp: new Date().toISOString() },
    };
  }

  async softDeleteMessage(
    eventId: string,
    messageId: string,
    user: AuthenticatedUser,
  ): Promise<{ data: { ok: true }; meta: { timestamp: string } }> {
    const msg = await this.prisma.eventChatMessage.findFirst({
      where: { id: messageId, eventId },
      include: {
        attachments: { select: { url: true, thumbnailUrl: true } },
      },
    });
    if (!msg) {
      throw new NotFoundException({
        code: 'EVENT_CHAT_MESSAGE_NOT_FOUND',
        message: 'Message not found',
      });
    }
    if (msg.deletedAt != null) {
      return { data: { ok: true }, meta: { timestamp: new Date().toISOString() } };
    }

    const isAuthor = msg.authorId === user.userId;
    if (!isAuthor) {
      throw new ForbiddenException({
        code: 'EVENT_CHAT_DELETE_FORBIDDEN',
        message: 'You can only delete your own messages',
      });
    }

    const s3Urls: string[] = [];
    for (const a of msg.attachments) {
      s3Urls.push(a.url);
      if (a.thumbnailUrl) {
        s3Urls.push(a.thumbnailUrl);
      }
    }

    await this.prisma.$transaction([
      this.prisma.eventChatAttachment.deleteMany({ where: { messageId } }),
      this.prisma.eventChatMessage.update({
        where: { id: messageId },
        data: {
          deletedAt: new Date(),
          isPinned: false,
          pinnedAt: null,
          pinnedById: null,
          locationLat: null,
          locationLng: null,
          locationLabel: null,
        },
      }),
    ]);

    await this.chatUpload.deleteUploadedObjectsByUrls(s3Urls);

    const streamEventId = randomUUID();
    this.sse.emitEvent({
      streamEventId,
      eventId,
      type: 'message_deleted',
      messageId,
    });

    this.telemetry.emitAudit('message_deleted', {
      actorId: user.userId,
      messageId,
      eventId,
    });

    return { data: { ok: true }, meta: { timestamp: new Date().toISOString() } };
  }

  async patchReadCursor(
    eventId: string,
    user: AuthenticatedUser,
    dto: PatchEventChatReadDto,
  ): Promise<{ data: { ok: true }; meta: { timestamp: string } }> {
    const lastRead = dto.lastReadMessageId?.trim() || null;
    if (lastRead) {
      const exists = await this.prisma.eventChatMessage.findFirst({
        where: { id: lastRead, eventId },
        select: { id: true },
      });
      if (!exists) {
        throw new BadRequestException({
          code: 'EVENT_CHAT_READ_MESSAGE_NOT_FOUND',
          message: 'Message not found in this event',
        });
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
    const displayName = reader
      ? `${reader.firstName} ${reader.lastName}`.trim()
      : '';

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

  private normalizeBody(raw: string): string {
    return raw
      .trim()
      .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '');
  }

  private async finalizeMessageDto(
    row: EventChatMessageRow,
    viewerUserId: string,
  ): Promise<EventChatMessageResponseDto> {
    const base = this.toDto(row, viewerUserId);
    const signed = await this.chatUpload.applySignedUrlsToMessageDto(base);
    const avatarUrl = await this.uploads.signPrivateObjectKey(row.author.avatarObjectKey);
    return {
      ...signed,
      author: {
        ...signed.author,
        avatarUrl,
      },
    };
  }

  private toDto(row: EventChatMessageRow, viewerUserId: string): EventChatMessageResponseDto {
    const isDeleted = row.deletedAt != null;
    const displayName = `${row.author.firstName} ${row.author.lastName}`.trim();
    let replyTo: EventChatMessageResponseDto['replyTo'] = null;
    if (row.replyTo) {
      const parentPlain = this.decryptStoredBody(
        row.replyTo.body,
        row.replyTo.bodyEncrypted,
        `reply parent ${row.replyTo.id}`,
      );
      const snippet = row.replyTo.deletedAt ? null : this.snippet(parentPlain);
      replyTo = { id: row.replyTo.id, snippet };
    }
    const pinnedByDisplayName =
      row.pinnedBy != null
        ? `${row.pinnedBy.firstName} ${row.pinnedBy.lastName}`.trim()
        : null;
    return {
      id: row.id,
      clientMessageId: row.clientMessageId ?? null,
      eventId: row.eventId,
      createdAt: row.createdAt.toISOString(),
      author: {
        id: row.author.id,
        displayName,
        avatarUrl: null,
      },
      body: isDeleted ? null : this.decryptBody(row),
      isDeleted,
      isOwnMessage: viewerUserId !== '' && row.authorId === viewerUserId,
      replyToId: row.replyToId,
      replyTo,
      editedAt: row.editedAt?.toISOString() ?? null,
      isPinned: row.isPinned,
      messageType: row.messageType,
      systemPayload: this.jsonToRecord(row.systemPayload),
      pinnedByDisplayName,
      attachments: isDeleted
        ? []
        : (row.attachments ?? []).map((a) => ({
            id: a.id,
            url: a.url,
            mimeType: a.mimeType,
            fileName: a.fileName,
            sizeBytes: a.sizeBytes,
            width: a.width,
            height: a.height,
            duration: a.duration ?? null,
            thumbnailUrl: a.thumbnailUrl ?? null,
          })),
      locationLat: isDeleted ? null : (row.locationLat ?? null),
      locationLng: isDeleted ? null : (row.locationLng ?? null),
      locationLabel: isDeleted ? null : (row.locationLabel ?? null),
    };
  }

  private jsonToRecord(v: Prisma.JsonValue | null): Record<string, unknown> | null {
    if (v == null || typeof v !== 'object' || Array.isArray(v)) {
      return null;
    }
    return v as Record<string, unknown>;
  }

  private decryptStoredBody(
    body: string | null,
    bodyEncrypted: boolean,
    logContext: string,
  ): string {
    if (!body) {
      return '';
    }
    if (bodyEncrypted && this.encryption.enabled) {
      try {
        return this.encryption.decrypt(body);
      } catch (error) {
        this.logger.warn(`Failed to decrypt ${logContext}: ${String(error)}`);
        return body;
      }
    }
    return body;
  }

  private decryptBody(row: EventChatMessageRow): string {
    return this.decryptStoredBody(row.body, row.bodyEncrypted, `message ${row.id}`);
  }

  private snippet(body: string): string {
    const t = body.trim();
    if (t.length <= REPLY_SNIPPET_MAX) {
      return t;
    }
    return `${t.slice(0, REPLY_SNIPPET_MAX)}…`;
  }

  private async notifyParticipantsDebounced(
    eventId: string,
    senderId: string,
    created: EventChatMessageRow,
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

    const preview = this.snippet(this.decryptBody(created));
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
}
