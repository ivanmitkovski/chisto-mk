import { ApiProperty } from '@nestjs/swagger';

export class AdminOverviewCleanupEventItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty()
  date!: string;
}

export class AdminOverviewCleanupEventsDto {
  @ApiProperty()
  upcoming!: number;

  @ApiProperty()
  completed!: number;

  @ApiProperty()
  pending!: number;

  @ApiProperty()
  totalParticipants!: number;

  @ApiProperty({ type: [AdminOverviewCleanupEventItemDto] })
  upcomingEvents!: AdminOverviewCleanupEventItemDto[];
}

export class AdminOverviewRecentActivityItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  createdAt!: string;

  @ApiProperty()
  action!: string;

  @ApiProperty()
  resourceType!: string;

  @ApiProperty({ nullable: true })
  resourceId!: string | null;

  @ApiProperty({ nullable: true })
  actorEmail!: string | null;
}

export class AdminOverviewReportsTrendItemDto {
  @ApiProperty()
  date!: string;

  @ApiProperty()
  count!: number;
}

export class AdminOverviewFeedReasonCodeDto {
  @ApiProperty()
  code!: string;

  @ApiProperty()
  count!: number;
}

export class AdminOverviewRankDriftItemDto {
  @ApiProperty()
  siteId!: string;

  @ApiProperty()
  score!: number;

  @ApiProperty({ type: 'array', items: { type: 'string' } })
  reasons!: string[];
}

export class AdminOverviewFeedDiagnosticsDto {
  @ApiProperty({ type: [AdminOverviewFeedReasonCodeDto] })
  reasonCodes!: AdminOverviewFeedReasonCodeDto[];

  @ApiProperty({ type: [AdminOverviewRankDriftItemDto] })
  rankDriftSnapshot!: AdminOverviewRankDriftItemDto[];

  @ApiProperty()
  recentIntegrityDemotions!: number;
}

export class AdminOverviewResponseDto {
  @ApiProperty({ type: 'object', additionalProperties: { type: 'number' } })
  reportsByStatus!: Record<string, number>;

  @ApiProperty({ type: 'object', additionalProperties: { type: 'number' } })
  sitesByStatus!: Record<string, number>;

  @ApiProperty()
  duplicateGroupsCount!: number;

  @ApiProperty({ type: AdminOverviewCleanupEventsDto })
  cleanupEvents!: AdminOverviewCleanupEventsDto;

  @ApiProperty()
  usersCount!: number;

  @ApiProperty()
  usersNewLast7d!: number;

  @ApiProperty()
  sessionsActive!: number;

  @ApiProperty({ type: [AdminOverviewReportsTrendItemDto] })
  reportsTrend!: AdminOverviewReportsTrendItemDto[];

  @ApiProperty({ type: [AdminOverviewRecentActivityItemDto] })
  recentActivity!: AdminOverviewRecentActivityItemDto[];

  @ApiProperty({ type: AdminOverviewFeedDiagnosticsDto })
  feedDiagnostics!: AdminOverviewFeedDiagnosticsDto;
}
