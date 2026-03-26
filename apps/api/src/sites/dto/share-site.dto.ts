import { ApiPropertyOptional } from '@nestjs/swagger';
import { SiteShareChannel } from '../../prisma-client';
import { IsEnum, IsOptional } from 'class-validator';

export class ShareSiteDto {
  @ApiPropertyOptional({ enum: SiteShareChannel, default: SiteShareChannel.native })
  @IsOptional()
  @IsEnum(SiteShareChannel)
  channel: SiteShareChannel = SiteShareChannel.native;
}
