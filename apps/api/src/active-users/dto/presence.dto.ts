import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsIn, IsOptional, IsString } from 'class-validator';
import { DevicePlatform } from '../../prisma-client';

export class PresenceHeartbeatDto {
  @ApiProperty()
  @IsString()
  screen!: string;

  @ApiProperty({ enum: ['foreground', 'background'] })
  @IsIn(['foreground', 'background'])
  appState!: 'foreground' | 'background';

  @ApiProperty({ enum: DevicePlatform })
  @IsEnum(DevicePlatform)
  platform!: DevicePlatform;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  appVersion?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  deviceModel?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  osVersion?: string;
}

export class PresenceOfflineDto {
  @ApiPropertyOptional({ description: 'Device id (falls back to X-Device-Id header)' })
  @IsOptional()
  @IsString()
  deviceId?: string;
}
