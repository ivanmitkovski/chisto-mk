import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class UpdateNotificationPreferenceDto {
  @ApiProperty({ description: 'Whether this notification type is muted (in-app + push)' })
  @Type(() => Boolean)
  @IsBoolean()
  muted!: boolean;

  @ApiProperty({
    required: false,
    description: 'Optional ISO timestamp until mute is active',
  })
  @IsOptional()
  @IsString()
  mutedUntil?: string;

  @ApiProperty({
    required: false,
    description: 'Whether transactional email for this type is muted',
  })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  emailMuted?: boolean;

  @ApiProperty({
    required: false,
    description: 'Optional ISO timestamp until email mute is active',
  })
  @IsOptional()
  @IsString()
  emailMutedUntil?: string;

  @ApiProperty({ required: false, description: 'Quiet hours start (minutes from midnight, 0–1439)' })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(1439)
  quietHoursStart?: number;

  @ApiProperty({ required: false, description: 'Quiet hours end (minutes from midnight, 0–1439)' })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(1439)
  quietHoursEnd?: number;

  @ApiProperty({ required: false, description: 'IANA timezone for quiet hours' })
  @IsOptional()
  @IsString()
  quietHoursTimezone?: string;
}
