import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateNotificationPreferenceDto {
  @ApiProperty({ description: 'Whether this notification type is muted' })
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
}
