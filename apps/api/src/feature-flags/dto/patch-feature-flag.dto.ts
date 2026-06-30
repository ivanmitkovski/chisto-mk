import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsObject } from 'class-validator';

export class PatchFeatureFlagDto {
  @ApiPropertyOptional()
  @IsBoolean()
  enabled!: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsObject()
  metadata?: Record<string, unknown>;
}
