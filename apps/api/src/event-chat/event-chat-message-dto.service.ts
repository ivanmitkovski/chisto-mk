import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import type { EventChatMessageResponseDto } from './dto/event-chat-message-response.dto';
import { ChatEncryptionService } from './chat-encryption.service';
import type { EventChatMessageRow } from './event-chat-message.select';
import { EventChatUploadService } from './event-chat-upload.service';
import { ReportsUploadService } from '../reports/reports-upload.service';

const REPLY_SNIPPET_MAX = 120;

@Injectable()
export class EventChatMessageDtoService {
  private readonly logger = new Logger(EventChatMessageDtoService.name);

  constructor(
    private readonly encryption: ChatEncryptionService,
    private readonly chatUpload: EventChatUploadService,
    private readonly uploads: ReportsUploadService,
  ) {}

  normalizeBody(raw: string): string {
    return raw
      .trim()
      .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '');
  }

  decryptBody(row: EventChatMessageRow): string {
    return this.decryptStoredBody(row.body, row.bodyEncrypted, `message ${row.id}`);
  }

  async finalizeMessageDto(
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

  private snippet(body: string): string {
    const t = body.trim();
    if (t.length <= REPLY_SNIPPET_MAX) {
      return t;
    }
    return `${t.slice(0, REPLY_SNIPPET_MAX)}…`;
  }
}
