import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsOptional, IsString, IsUUID, Matches, MaxLength, ValidateNested } from 'class-validator';

import { GeoPointLatLngWithLabelDto } from '../../common/dto/geo-point.dto';
import { PRISMA_CUID_REGEX } from '../../common/validators/is-cuid.validator';

export class ChatLocationDto extends GeoPointLatLngWithLabelDto {}

export class SendEventChatMessageDto {
  @ApiProperty({
    example: 'See you at the north entrance',
    maxLength: 2000,
    description:
      'Plain text. May be empty when sending only attachments (e.g. voice) or a location pin.',
  })
  @IsString()
  @MaxLength(2000)
  body!: string;

  @ApiPropertyOptional({ description: 'Parent message id for a reply thread (Prisma cuid)' })
  @IsOptional()
  @Matches(PRISMA_CUID_REGEX, { message: 'replyToId must be a valid cuid' })
  replyToId?: string;

  @ApiPropertyOptional({
    description: 'Pre-uploaded attachment metadata (from /chat/upload). Each item has url, mimeType, fileName, sizeBytes, width, height.',
    type: 'array',
    items: { type: 'object' },
  })
  @IsOptional()
  @IsArray()
  attachments?: Array<{
    url: string;
    mimeType: string;
    fileName: string;
    sizeBytes: number;
    width?: number | null;
    height?: number | null;
    duration?: number | null;
    thumbnailUrl?: string | null;
  }>;

  @ApiPropertyOptional({ description: 'Location payload (creates a LOCATION message)', type: ChatLocationDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => ChatLocationDto)
  location?: ChatLocationDto;

  @ApiPropertyOptional({
    description: 'Client-generated UUID v4 for idempotent sends (safe retries after network loss)',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsOptional()
  @IsUUID('4')
  clientMessageId?: string;
}
