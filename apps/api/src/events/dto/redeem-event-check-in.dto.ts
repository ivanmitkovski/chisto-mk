import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class RedeemEventCheckInDto {
  @ApiProperty({ description: 'Raw QR string from organizer (signed v2 token)' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @IsNotEmpty()
  @MinLength(16)
  qrPayload!: string;
}
