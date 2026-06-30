import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsDateString, IsOptional, IsString, Matches } from 'class-validator';
import { PRISMA_CUID_REGEX } from '../../common/validators/is-cuid.validator';

export class CheckEventConflictQueryDto {
  @ApiProperty({ description: 'Pollution site id' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @Matches(PRISMA_CUID_REGEX, { message: 'siteId must be a valid cuid' })
  siteId!: string;

  @ApiProperty({ description: 'Proposed event start (ISO 8601)' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsDateString()
  scheduledAt!: string;

  @ApiPropertyOptional({ description: 'Proposed event end (ISO 8601); omit for point-in-time' })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsDateString()
  endAt?: string;

  @ApiPropertyOptional({ description: 'Event id to exclude (e.g. when editing)' })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @Matches(PRISMA_CUID_REGEX, { message: 'excludeEventId must be a valid cuid' })
  excludeEventId?: string;
}
