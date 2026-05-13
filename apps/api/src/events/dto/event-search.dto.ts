import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsDateString,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
} from 'class-validator';

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 30;

export class EventSearchDto {
  @ApiPropertyOptional({ description: 'Search text (min 2 chars)', example: 'river cleanup' })
  @Transform(({ value }) => {
    if (value == null || value === '') {
      return undefined;
    }
    if (typeof value === 'string') {
      const t = value.trim();
      return t.length === 0 ? undefined : t;
    }
    return value;
  })
  @IsString()
  @MinLength(2, { message: 'query must be at least 2 characters' })
  query!: string;

  @ApiPropertyOptional({ description: 'Max results (1–30)', default: DEFAULT_LIMIT })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({ description: 'Optional proximity hint (latitude)' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  nearLat?: number;

  @ApiPropertyOptional({ description: 'Optional proximity hint (longitude)' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  nearLng?: number;

  @ApiPropertyOptional({
    description: 'Comma-separated lifecycle filters (same as GET /events status)',
  })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  status?: string;

  @ApiPropertyOptional({ description: 'Comma-separated category keys' })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  category?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  siteId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsDateString()
  dateFrom?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsDateString()
  dateTo?: string;

  getLimit(): number {
    const n = this.limit ?? DEFAULT_LIMIT;
    return Math.min(MAX_LIMIT, Math.max(1, n));
  }
}
