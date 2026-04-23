import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsNotEmpty, IsNumber, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';

export class RedeemEventCheckInDto {
  @ApiProperty({ description: 'Raw QR string from organizer (signed v2 token)' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @IsNotEmpty()
  @MinLength(16)
  qrPayload!: string;

  @ApiPropertyOptional({ description: 'Optional attendee GPS latitude (WGS84) for anti-gaming signals' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  redeemLatitude?: number;

  @ApiPropertyOptional({ description: 'Optional attendee GPS longitude (WGS84)' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  redeemLongitude?: number;
}
