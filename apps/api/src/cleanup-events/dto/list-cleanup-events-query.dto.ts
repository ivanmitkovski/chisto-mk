import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, Max, Min } from 'class-validator';

export class ListCleanupEventsQueryDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;

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
}
