import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';
import { PRISMA_CUID_REGEX } from '../../common/validators/is-cuid.validator';
import { EcoEventLifecycleStatus } from '../../prisma-client';

export class EventPublicShareCardResponseDto {
  @ApiProperty({ description: 'CleanupEvent id (Prisma cuid)' })
  @Matches(PRISMA_CUID_REGEX, { message: 'id must be a valid cuid' })
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty({ description: 'City / area line (same rules as mobile siteName)' })
  siteLabel!: string;

  @ApiProperty({ type: String, format: 'date-time' })
  scheduledAt!: string;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  endAt!: string | null;

  @ApiProperty({ enum: EcoEventLifecycleStatus })
  lifecycleStatus!: EcoEventLifecycleStatus;
}
