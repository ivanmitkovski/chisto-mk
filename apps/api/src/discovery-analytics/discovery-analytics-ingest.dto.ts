import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class DiscoveryAnalyticsIngestDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  eventId!: string;

  @ApiProperty({ enum: ['detail_view', 'join_success', 'check_in_success'] })
  @IsString()
  @IsIn(['detail_view', 'join_success', 'check_in_success'])
  step!: string;

  @ApiProperty({ enum: ['ios', 'android'] })
  @IsString()
  @IsIn(['ios', 'android'])
  platform!: string;

  @ApiProperty({ maxLength: 40 })
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  appVersion!: string;
}
