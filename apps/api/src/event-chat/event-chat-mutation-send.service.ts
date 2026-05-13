import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { EventChatMessageType, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { EventChatMessageResponseDto } from './dto/event-chat-message-response.dto';
import type { SendEventChatMessageDto } from './dto/send-event-chat-message.dto';
import { ChatEncryptionService } from './chat-encryption.service';
import { EVENT_CHAT_MESSAGE_SELECT, type EventChatMessageRow } from './event-chat-message.select';
import { EventChatNotificationsService } from './event-chat-notifications.service';
import { EventChatSseService } from './event-chat-sse.service';
import { EventChatTelemetryService } from './event-chat-telemetry.service';
import { EventChatUploadService } from './event-chat-upload.service';
import { EventChatMessageDtoService } from './event-chat-message-dto.service';

@Injectable()
export class EventChatMutationSendService {
  private readonly logger = new Logger(EventChatMutationSendService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly sse: EventChatSseService,
    private readonly chatNotifications: EventChatNotificationsService,
    private readonly encryption: ChatEncryptionService,
    private readonly chatUpload: EventChatUploadService,
    private readonly telemetry: EventChatTelemetryService,
    private readonly dto: EventChatMessageDtoService,
  ) {}

  async sendMessage(
    eventId: string,
    user: AuthenticatedUser,
    dto: SendEventChatMessageDto,
  ): Promise<{ data: EventChatMessageResponseDto; meta: { timestamp: string } }> {
    const body = this.dto.normalizeBody(dto.body);
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

    for (const a of attachData) {
      if (!this.chatUpload.isTrustedChatPublishedUrl(a.url)) {
        throw new BadRequestException({
          code: 'EVENT_CHAT_ATTACHMENT_URL_INVALID',
          message: 'Attachment URL must come from the official event chat upload',
        });
      }
      if (
        a.thumbnailUrl != null &&
        a.thumbnailUrl !== '' &&
        !this.chatUpload.isTrustedChatPublishedUrl(a.thumbnailUrl)
      ) {
        throw new BadRequestException({
          code: 'EVENT_CHAT_ATTACHMENT_URL_INVALID',
          message: 'Thumbnail URL must come from the official event chat upload',
        });
      }
    }

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
          data: await this.dto.finalizeMessageDto(existing, user.userId),
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
            data: await this.dto.finalizeMessageDto(retry, user.userId),
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
    const streamPayload = await this.dto.finalizeMessageDto(created, '');
    this.sse.emitEvent({
      streamEventId,
      eventId,
      type: 'message_created',
      message: streamPayload as unknown as Record<string, unknown>,
    });

    const messagePreview = this.dto.decryptBody(created);
    void this.chatNotifications
      .notifyParticipantsDebounced(eventId, user.userId, created, messagePreview)
      .catch((err: unknown) => {
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
      data: await this.dto.finalizeMessageDto(created, user.userId),
      meta: { timestamp: new Date().toISOString() },
    };
  }

  async createSystemMessage(params: {
    eventId: string;
    authorId: string;
    body: string;
    systemPayload: Prisma.InputJsonValue;
  }): Promise<void> {
    const body = this.dto.normalizeBody(params.body);
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
    const streamPayload = await this.dto.finalizeMessageDto(created, '');
    this.sse.emitEvent({
      streamEventId,
      eventId: params.eventId,
      type: 'message_created',
      message: streamPayload as unknown as Record<string, unknown>,
    });
  }
}
