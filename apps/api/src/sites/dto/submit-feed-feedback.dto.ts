import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsObject, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export enum FeedFeedbackType {
  NOT_RELEVANT = 'not_relevant',
  SHOW_MORE = 'show_more',
  MISLEADING = 'misleading',
  DUPLICATE = 'duplicate',
}

export class SubmitFeedFeedbackDto {
  @ApiProperty({ enum: FeedFeedbackType })
  @IsEnum(FeedFeedbackType)
  feedbackType!: FeedFeedbackType;

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
