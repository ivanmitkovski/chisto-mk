import { ApiProperty } from '@nestjs/swagger';
import { SiteStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class UpdateSiteStatusDto {
  @ApiProperty({ enum: SiteStatus })
  @IsEnum(SiteStatus)
  status!: SiteStatus;
}
