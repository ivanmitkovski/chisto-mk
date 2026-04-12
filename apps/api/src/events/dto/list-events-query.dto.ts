import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsDateString, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;

export class ListEventsQueryDto {
  @ApiPropertyOptional({
    description: 'Max items (1–50)',
    default: DEFAULT_LIMIT,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({
    description: 'Opaque cursor from previous response meta.nextCursor',
  })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({
    description: 'Comma-separated lifecycle filters: upcoming,inProgress,completed,cancelled',
    example: 'upcoming,inProgress',
  })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  status?: string;

  @ApiPropertyOptional({
    description:
      'Mobile category key(s): one key or comma-separated list (e.g. riverAndLake,treeAndGreen)',
  })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  category?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  siteId?: string;

  @ApiPropertyOptional({
    description: 'Full-text search across title and description (case-insensitive, min 2 chars)',
    example: 'river cleanup',
  })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  q?: string;

  @ApiPropertyOptional({
    description: 'ISO 8601 date — only return events on or after this date',
    example: '2026-04-01',
  })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsDateString()
  dateFrom?: string;

  @ApiPropertyOptional({
    description: 'ISO 8601 date — only return events on or before this date',
    example: '2026-04-30',
  })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsDateString()
  dateTo?: string;

  getLimit(): number {
    const n = this.limit ?? DEFAULT_LIMIT;
    return Math.min(MAX_LIMIT, Math.max(1, n));
  }
}
