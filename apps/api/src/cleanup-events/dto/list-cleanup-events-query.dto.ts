import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';

import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';

export class ListCleanupEventsQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by completion (upcoming/completed)',
    enum: ['upcoming', 'completed'],
  })
  @IsOptional()
  @IsIn(['upcoming', 'completed'])
  status?: 'upcoming' | 'completed';

  @ApiPropertyOptional({
    description: 'Filter by moderation status',
    enum: ['PENDING', 'APPROVED', 'DECLINED'],
  })
  @IsOptional()
  @IsIn(['PENDING', 'APPROVED', 'DECLINED'])
  moderationStatus?: 'PENDING' | 'APPROVED' | 'DECLINED';

  @ApiPropertyOptional({ description: 'Substring match on title or description (min 2 chars)' })
  @IsOptional()
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
  @MinLength(2)
  q?: string;
}
