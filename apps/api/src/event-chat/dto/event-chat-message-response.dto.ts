import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class EventChatMessageAuthorDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  displayName!: string;

  @ApiPropertyOptional({
    nullable: true,
    description: 'Signed HTTPS URL when the author has a profile photo',
  })
  avatarUrl!: string | null;
}

export class EventChatMessageReplyPreviewDto {
  @ApiProperty()
  id!: string;

  @ApiPropertyOptional()
  snippet?: string | null;
}

export class EventChatAttachmentDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  url!: string;

  @ApiProperty()
  mimeType!: string;

  @ApiProperty()
  fileName!: string;

  @ApiProperty()
  sizeBytes!: number;

  @ApiPropertyOptional()
  width!: number | null;

  @ApiPropertyOptional()
  height!: number | null;

  @ApiPropertyOptional({ description: 'Duration in seconds (video/audio)' })
  duration!: number | null;

  @ApiPropertyOptional({ description: 'Thumbnail URL (video)' })
  thumbnailUrl!: string | null;
}

export class EventChatMessageResponseDto {
  @ApiProperty()
  id!: string;

  @ApiPropertyOptional({
    description: 'Echo of client idempotency key when the client supplied one',
  })
  clientMessageId!: string | null;

  @ApiProperty()
  eventId!: string;

  @ApiProperty()
  createdAt!: string;

  @ApiProperty({ type: EventChatMessageAuthorDto })
  author!: EventChatMessageAuthorDto;

  @ApiPropertyOptional({ description: 'Null when message was removed' })
  body!: string | null;

  @ApiProperty()
  isDeleted!: boolean;

  @ApiProperty({ description: 'True when the current user authored this message' })
  isOwnMessage!: boolean;

  @ApiPropertyOptional()
  replyToId!: string | null;

  @ApiPropertyOptional({ type: EventChatMessageReplyPreviewDto })
  replyTo!: EventChatMessageReplyPreviewDto | null;

  @ApiPropertyOptional({ description: 'ISO timestamp when the message was last edited' })
  editedAt!: string | null;

  @ApiProperty()
  isPinned!: boolean;

  @ApiProperty({ enum: ['TEXT', 'SYSTEM', 'IMAGE', 'LOCATION', 'VIDEO', 'AUDIO', 'FILE'] })
  messageType!: 'TEXT' | 'SYSTEM' | 'IMAGE' | 'LOCATION' | 'VIDEO' | 'AUDIO' | 'FILE';

  @ApiPropertyOptional({ description: 'Structured payload for SYSTEM messages' })
  systemPayload!: Record<string, unknown> | null;

  @ApiPropertyOptional({ description: 'Display name of user who pinned (when pinned)' })
  pinnedByDisplayName!: string | null;

  @ApiPropertyOptional({ type: [EventChatAttachmentDto], description: 'Image attachments for IMAGE messages' })
  attachments!: EventChatAttachmentDto[];

  @ApiPropertyOptional({ description: 'Latitude for LOCATION messages' })
  locationLat!: number | null;

  @ApiPropertyOptional({ description: 'Longitude for LOCATION messages' })
  locationLng!: number | null;

  @ApiPropertyOptional({ description: 'Human-readable label for LOCATION messages' })
  locationLabel!: string | null;
}
