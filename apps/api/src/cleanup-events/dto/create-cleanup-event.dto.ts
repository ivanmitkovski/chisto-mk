import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDateString, IsEnum, IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';
import { CleanupEventStatus } from '../../prisma-client';

export class CreateCleanupEventDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  siteId!: string;

  @ApiProperty()
  @IsDateString()
  scheduledAt!: string;

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
