import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { EventChatMessageType } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { EventChatMessageResponseDto } from './dto/event-chat-message-response.dto';
import type { EditEventChatMessageDto } from './dto/edit-event-chat-message.dto';
import type { PinEventChatMessageDto } from './dto/pin-event-chat-message.dto';
import { ChatEncryptionService } from './chat-encryption.service';
import { EVENT_CHAT_MESSAGE_SELECT } from './event-chat-message.select';
import { EventChatSseService } from './event-chat-sse.service';
import { EventChatTelemetryService } from './event-chat-telemetry.service';
import { EventChatUploadService } from './event-chat-upload.service';
import { EventChatMessageDtoService } from './event-chat-message-dto.service';
import { MAX_PINNED_PER_EVENT } from './event-chat.constants';

@Injectable()
export class EventChatMutationModerateService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sse: EventChatSseService,
    private readonly encryption: ChatEncryptionService,
    private readonly chatUpload: EventChatUploadService,
    private readonly telemetry: EventChatTelemetryService,
    private readonly dto: EventChatMessageDtoService,
  ) {}

  async editMessage(
    eventId: string,
    messageId: string,
    user: AuthenticatedUser,
    dto: EditEventChatMessageDto,
  ): Promise<{ data: EventChatMessageResponseDto; meta: { timestamp: string } }> {
    const body = this.dto.normalizeBody(dto.body);
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

    const shouldEncrypt = this.encryption.enabled;
    const storedBody = shouldEncrypt ? this.encryption.encrypt(body) : body;

    const updated = await this.prisma.eventChatMessage.update({
      where: { id: messageId },
      data: {
        body: storedBody,
        bodyEncrypted: shouldEncrypt,
        editedAt: new Date(),
      },
      select: EVENT_CHAT_MESSAGE_SELECT,
    });

    const streamEventId = randomUUID();
    const streamPayload = await this.dto.finalizeMessageDto(updated, '');
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
      data: await this.dto.finalizeMessageDto(updated, user.userId),
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
      const streamPayload = await this.dto.finalizeMessageDto(updated, '');
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
        data: await this.dto.finalizeMessageDto(updated, user.userId),
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
    const streamUnpin = await this.dto.finalizeMessageDto(updated, '');
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
      data: await this.dto.finalizeMessageDto(updated, user.userId),
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
}
