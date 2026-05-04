import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ReportSubmitPointsBreakdownLineDto {
  @ApiProperty({ example: 'REPORT_APPROVED_BASE' })
  code!: string;

  @ApiProperty({ example: 5 })
  points!: number;
}

export class ReportSubmitResponseDto {
  @ApiProperty({ description: 'Created report ID' })
  reportId!: string;

  @ApiProperty({ description: 'Human-friendly report number (e.g. CH-000001)' })
  reportNumber!: string;

  @ApiProperty({ description: 'Site ID (existing or newly created)' })
  siteId!: string;

  @ApiProperty({ description: 'True if a new site was created, false if linked to existing site' })
  isNewSite!: boolean;

  @ApiProperty({
    description:
      'Net report-scoped XP for this submission (0 on create). Points are granted when moderators approve; idempotent replay returns the same net if the ledger changed.',
  })
  pointsAwarded!: number;

  @ApiPropertyOptional({
    type: () => [ReportSubmitPointsBreakdownLineDto],
    description:
      'Breakdown from the latest approval grant metadata (or legacy submit grant) when available',
  })
  pointsBreakdown?: ReportSubmitPointsBreakdownLineDto[];
}
