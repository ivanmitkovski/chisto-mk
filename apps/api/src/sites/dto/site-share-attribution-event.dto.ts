import { ApiProperty } from '@nestjs/swagger';
import { SiteShareAttributionEventType, SiteShareAttributionSource } from '../../prisma-client';
import { IsEnum, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class SiteShareAttributionEventDto {
  @ApiProperty({ description: 'Opaque signed share token from share URL' })
  @IsString()
  @MinLength(16)
  @MaxLength(1024)
  token!: string;

  @ApiProperty({
    enum: SiteShareAttributionEventType,
    description: 'Attribution event type (CLICK on web, OPEN in-app)',
  })
  @IsEnum(SiteShareAttributionEventType)
  eventType!: SiteShareAttributionEventType;

  @ApiProperty({
    enum: SiteShareAttributionSource,
    required: false,
    default: SiteShareAttributionSource.OTHER,
  })
  @IsOptional()
  @IsEnum(SiteShareAttributionSource)
  source: SiteShareAttributionSource = SiteShareAttributionSource.OTHER;
}
