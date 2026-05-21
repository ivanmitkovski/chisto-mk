import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

const SUBJECT_TYPES = [
  'site_comment',
  'event_chat_message',
  'user',
  'site',
  'event',
  'safety_issue',
] as const;

const REASONS = ['spam', 'harassment', 'hate', 'violence', 'nudity', 'other'] as const;

export class PostUgcReportDto {
  @ApiProperty({ enum: SUBJECT_TYPES })
  @IsIn([...SUBJECT_TYPES])
  subjectType!: (typeof SUBJECT_TYPES)[number];

  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  subjectId!: string;

  @ApiProperty({ enum: REASONS })
  @IsIn([...REASONS])
  reason!: (typeof REASONS)[number];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  details?: string;
}
