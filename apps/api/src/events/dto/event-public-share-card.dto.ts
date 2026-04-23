import { ApiProperty } from '@nestjs/swagger';
import { EcoEventLifecycleStatus } from '../../prisma-client';

export class EventPublicShareCardResponseDto {
  @ApiProperty({ format: 'uuid' })
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
