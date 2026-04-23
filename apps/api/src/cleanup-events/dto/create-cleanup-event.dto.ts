import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  MinLength,
  Matches,
  ValidateIf,
} from 'class-validator';
import { CleanupEventStatus } from '../../prisma-client';

/** Optional RFC 5545 RRULE line (with or without `RRULE:` prefix). Stored on the event; not expanded server-side for admin creates. */
const RRULE_MAX = 2048;

export class CreateCleanupEventDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  siteId!: string;

  @ApiProperty()
  @IsDateString()
  scheduledAt!: string;

  @ApiPropertyOptional({
    description:
      'When omitted, end is set to the same local wall time on the next calendar day (Europe/Skopje).',
  })
  @IsOptional()
  @ValidateIf((_: unknown, o: CreateCleanupEventDto) => o.endAt != null && String(o.endAt).trim() !== '')
  @IsDateString()
  endAt?: string;

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

  @ApiPropertyOptional({
    description: 'Optional recurrence rule (RFC 5545). Stored as metadata for this single event.',
    maxLength: RRULE_MAX,
  })
  @IsOptional()
  @IsString()
  @MaxLength(RRULE_MAX)
  @Matches(/^[\x09\x0A\x0D\x20-\x7E]*$/, {
    message: 'recurrenceRule must be printable ASCII',
  })
  recurrenceRule?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  completedAt?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  organizerId?: string;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  participantCount?: number;

  @ApiPropertyOptional({
    description: 'PENDING for user-created (requires admin approval), APPROVED for admin-created',
    enum: ['PENDING', 'APPROVED'],
  })
  @IsOptional()
  @IsEnum(CleanupEventStatus)
  status?: CleanupEventStatus;
}
