import { ApiProperty } from '@nestjs/swagger';
import { SiteShareChannel } from '../../prisma-client';

export class SiteShareLinkResponseDto {
  @ApiProperty()
  siteId!: string;

  @ApiProperty()
  cid!: string;

  @ApiProperty()
  url!: string;

  @ApiProperty()
  token!: string;

  @ApiProperty({ enum: SiteShareChannel })
  channel!: SiteShareChannel;

  @ApiProperty()
  expiresAt!: string;
}
