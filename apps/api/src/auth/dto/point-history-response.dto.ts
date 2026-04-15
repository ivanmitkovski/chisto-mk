import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PointHistoryMilestoneDto {
  @ApiProperty({ description: 'When the new level was reached (ISO-8601)' })
  reachedAt!: string;

  @ApiProperty({ description: '1-based level after the XP event' })
  level!: number;

  @ApiProperty({ description: 'Tier key for client icons (e.g. numeric_3, prestige_01)' })
  levelTierKey!: string;

  @ApiProperty({ description: 'English display name; clients may localize via levelTierKey' })
  levelDisplayName!: string;
}

export class PointHistoryItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({ description: 'Transaction time (ISO-8601)' })
  createdAt!: string;

  @ApiProperty({ description: 'Points change (positive for awards)' })
  delta!: number;

  @ApiProperty({
    description:
      'Machine reason (e.g. FIRST_REPORT, EVENT_JOINED, EVENT_CHECK_IN, EVENT_COMPLETED, EVENT_ORGANIZER_APPROVED)',
  })
  reasonCode!: string;

  @ApiPropertyOptional({ nullable: true })
  referenceType!: string | null;

  @ApiPropertyOptional({ nullable: true })
  referenceId!: string | null;
}

export class PointHistoryMetaDto {
  @ApiProperty({
    type: [PointHistoryMilestoneDto],
    description: 'Level-up moments derived from positive XP deltas (first page only)',
  })
  milestones!: PointHistoryMilestoneDto[];

  @ApiPropertyOptional({
    nullable: true,
    description: 'Pass as `cursor` to fetch the next page',
  })
  nextCursor!: string | null;
}

export class PointHistoryResponseDto {
  @ApiProperty({ type: [PointHistoryItemDto] })
  data!: PointHistoryItemDto[];

  @ApiProperty({ type: PointHistoryMetaDto })
  meta!: PointHistoryMetaDto;
}
