import { ApiProperty } from '@nestjs/swagger';
import { ReportStatus } from '../../prisma-client';

export class CitizenReportSiteDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  latitude!: number;

  @ApiProperty()
  longitude!: number;

  @ApiProperty({ nullable: true })
  description!: string | null;

  @ApiProperty({
    nullable: true,
    description: 'Structured place line when available (not the report narrative)',
  })
  address!: string | null;
}

export class CitizenReportDetailDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({ example: 'R-25-ABCD' })
  reportNumber!: string;

  @ApiProperty({ enum: ReportStatus })
  status!: ReportStatus;

  @ApiProperty()
  description!: string | null;

  @ApiProperty({ type: [String], description: 'Media URLs' })
  mediaUrls!: string[];

  @ApiProperty()
  submittedAt!: string;

  @ApiProperty({ type: () => CitizenReportSiteDto })
  site!: CitizenReportSiteDto;

  @ApiProperty({ nullable: true, description: 'Reporter display name' })
  reporterName!: string | null;

  @ApiProperty({ type: [String], description: 'Co-reporter display names' })
  coReporterNames!: string[];

  @ApiProperty()
  location!: string;

  @ApiProperty({ description: 'Points awarded when admin approved (0 if pending/denied)' })
  pointsAwarded!: number;

  @ApiProperty({ nullable: true, description: 'Report category' })
  category!: string | null;

  @ApiProperty({ nullable: true, description: 'Severity 1-5' })
  severity!: number | null;

  @ApiProperty({
    nullable: true,
    description: 'Cleanup effort (ONE_TO_TWO, THREE_TO_FIVE, …) when citizen provided it',
  })
  cleanupEffort!: string | null;
}
