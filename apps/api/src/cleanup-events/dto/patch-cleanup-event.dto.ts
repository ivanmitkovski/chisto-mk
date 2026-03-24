import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDateString, IsEnum, IsInt, IsOptional, Min } from 'class-validator';
import { CleanupEventStatus } from '../../prisma-client';

export class PatchCleanupEventDto {
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
    description: 'Moderation status: APPROVED or DECLINED',
    enum: ['APPROVED', 'DECLINED'],
  })
  @IsOptional()
  @IsEnum(CleanupEventStatus)
  status?: CleanupEventStatus;
}
