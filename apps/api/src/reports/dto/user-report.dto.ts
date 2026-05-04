import { ApiProperty } from '@nestjs/swagger';
import { ReportStatus } from '../../prisma-client';

/** How the current user relates to this report row in GET /reports/me. */
export type UserReportViewerRole = 'primary' | 'co_reporter';

export class UserReportListItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({
    description: 'Human-readable report number, e.g. R-25-ABCD',
  })
  reportNumber!: string;

  @ApiProperty({
    description: 'Short headline for the report',
  })
  title!: string;

  @ApiProperty({
    nullable: true,
    description: 'Optional extra context from the reporter (subtitle)',
  })
  description!: string | null;

  @ApiProperty({
    description: 'Location label derived from site description or coordinates',
  })
  location!: string;

  @ApiProperty({
    description: 'When the report was submitted (ISO timestamp)',
  })
  submittedAt!: string;

  @ApiProperty({ enum: ReportStatus })
  status!: ReportStatus;

  @ApiProperty({
    description: 'Whether this report is potentially a duplicate of another',
  })
  isPotentialDuplicate!: boolean;

  @ApiProperty({
    description: 'How many other reporters are attached as co-reporters',
  })
  coReporterCount!: number;

  @ApiProperty({
    description: 'Presigned URLs for evidence photos (first image for list thumbnail)',
    type: [String],
  })
  mediaUrls!: string[];

  @ApiProperty({
    description: 'Points awarded when admin approved this report (0 if pending or denied)',
  })
  pointsAwarded!: number;

  @ApiProperty({ nullable: true, description: 'Report category' })
  category!: string | null;

  @ApiProperty({ nullable: true, description: 'Severity 1-5' })
  severity!: number | null;

  @ApiProperty({
    nullable: true,
    description: 'Cleanup effort enum key when provided (ONE_TO_TWO, THREE_TO_FIVE, …)',
  })
  cleanupEffort!: string | null;

  @ApiProperty({
    enum: ['primary', 'co_reporter'],
    description: 'Whether this row is owned as primary reporter or visible as a co-reporter on the canonical report',
  })
  viewerRole!: UserReportViewerRole;
}

