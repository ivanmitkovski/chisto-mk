import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';
import { PRISMA_CUID_REGEX } from '../../common/validators/is-cuid.validator';
import { SiteStatus } from '../../prisma-client';

export class SitePublicShareCardResponseDto {
  @ApiProperty({ description: 'Site id (Prisma cuid)' })
  @Matches(PRISMA_CUID_REGEX, { message: 'id must be a valid cuid' })
  id!: string;

  @ApiProperty({ description: 'Headline from canonical hero report or first approved report' })
  title!: string;

  @ApiProperty({ description: 'City / area line (same rules as mobile siteName)' })
  siteLabel!: string;

  @ApiProperty({ enum: SiteStatus })
  status!: SiteStatus;
}
