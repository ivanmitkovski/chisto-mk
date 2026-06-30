import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsObject, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export enum FeedEventType {
  IMPRESSION = 'impression',
  DWELL_BUCKET = 'dwell_bucket',
  DETAIL_OPEN = 'detail_open',
  COMMENT_OPEN = 'comment_open',
  SAVE = 'save',
  SHARE = 'share',
  UPVOTE = 'upvote',
  SKIP = 'skip',
  BOUNCE = 'bounce',
}

export class TrackFeedEventDto {
  @ApiProperty({ enum: FeedEventType })
  @IsEnum(FeedEventType)
  eventType!: FeedEventType;

  @ApiProperty({ example: 'site_123' })
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  siteId!: string;

  @ApiProperty({ required: false, example: 'session_abc_123' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  sessionId?: string;

  @ApiProperty({ required: false, type: Object })
  @IsOptional()
  @IsObject()
  metadata?: Record<string, unknown>;
}
