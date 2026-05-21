import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteHistoryEntryKind, SiteStatus } from '../../../prisma-client';

export class SiteHistoryActorDto {
  @ApiProperty()
  id!: string;

  @ApiPropertyOptional()
  displayName!: string | null;

  @ApiPropertyOptional()
  role!: string | null;
}

export class SiteHistoryEntryDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({ enum: SiteHistoryEntryKind })
  kind!: SiteHistoryEntryKind;

  @ApiProperty()
  occurredAt!: string;

  @ApiPropertyOptional({ enum: SiteStatus })
  fromStatus!: SiteStatus | null;

  @ApiPropertyOptional({ enum: SiteStatus })
  toStatus!: SiteStatus | null;

  @ApiPropertyOptional()
  reportId!: string | null;

  @ApiPropertyOptional()
  cleanupEventId!: string | null;

  @ApiPropertyOptional({ type: SiteHistoryActorDto })
  actor!: SiteHistoryActorDto | null;

  @ApiPropertyOptional()
  note!: string | null;

  @ApiPropertyOptional()
  metadata!: Record<string, unknown> | null;
}

export class SiteHistoryListResponseDto {
  @ApiProperty({ type: [SiteHistoryEntryDto] })
  items!: SiteHistoryEntryDto[];

  @ApiPropertyOptional({ description: 'Cursor for the next page (entry id)' })
  nextBeforeId!: string | null;
}
