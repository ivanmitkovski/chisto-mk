import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

const DEFAULT_LIMIT = 30;
const MAX_LIMIT = 100;

export class ListEventParticipantsQueryDto {
  @ApiPropertyOptional({
    description: 'Max participants per page (1–100)',
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

  getLimit(): number {
    const n = this.limit ?? DEFAULT_LIMIT;
    return Math.min(MAX_LIMIT, Math.max(1, n));
  }
}
