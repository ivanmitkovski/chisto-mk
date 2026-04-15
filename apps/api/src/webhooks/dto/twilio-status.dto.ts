import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString } from 'class-validator';

const TWILIO_MESSAGE_STATUSES = [
  'queued',
  'sent',
  'delivered',
  'failed',
  'undelivered',
] as const;

export type TwilioMessageStatus = (typeof TWILIO_MESSAGE_STATUSES)[number];

/**
 * Twilio Status Callback POST body (`application/x-www-form-urlencoded`).
 * Field names match Twilio’s casing (e.g. `MessageSid`).
 */
export class TwilioStatusDto {
  @ApiProperty({ example: 'SMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' })
  @IsString()
  MessageSid!: string;

  @ApiProperty({ enum: TWILIO_MESSAGE_STATUSES })
  @IsString()
  @IsIn(TWILIO_MESSAGE_STATUSES)
  MessageStatus!: TwilioMessageStatus;

  @ApiProperty({ example: '+38970123456' })
  @IsString()
  To!: string;

  @ApiProperty({ example: '+15005550006' })
  @IsString()
  From!: string;

  @ApiPropertyOptional({ example: '30007' })
  @IsOptional()
  @IsString()
  ErrorCode?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  ErrorMessage?: string;
}
