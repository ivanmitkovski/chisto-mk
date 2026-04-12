import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  Matches,
} from 'class-validator';
import { CleanupEventStatus } from '../../prisma-client';

const RRULE_MAX = 2048;

export class PatchCleanupEventDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(10_000)
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  completedAt?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  participantCount?: number;

  @ApiPropertyOptional({
    description: 'Optional recurrence rule (RFC 5545). Empty string clears.',
    maxLength: RRULE_MAX,
  })
  @IsOptional()
  @IsString()
  @MaxLength(RRULE_MAX)
  @Matches(/^[\x09\x0A\x0D\x20-\x7E]*$/, {
    message: 'recurrenceRule must be printable ASCII',
  })
  recurrenceRule?: string;

  @ApiPropertyOptional({
    description: 'Moderation status: APPROVED or DECLINED',
    enum: ['APPROVED', 'DECLINED'],
  })
  @IsOptional()
  @IsEnum(CleanupEventStatus)
  status?: CleanupEventStatus;
}
