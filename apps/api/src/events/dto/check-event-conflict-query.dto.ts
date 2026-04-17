import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsDateString, IsOptional, IsString, MinLength } from 'class-validator';

export class CheckEventConflictQueryDto {
  @ApiProperty({ description: 'Pollution site id' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(1)
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
  @MinLength(1)
  excludeEventId?: string;
}
