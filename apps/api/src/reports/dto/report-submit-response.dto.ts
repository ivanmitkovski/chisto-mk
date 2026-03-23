import { ApiProperty } from '@nestjs/swagger';

export class ReportSubmitResponseDto {
  @ApiProperty({ description: 'Created report ID' })
  reportId!: string;

  @ApiProperty({ description: 'Human-friendly report number (e.g. CH-000001)' })
  reportNumber!: string;

  @ApiProperty({ description: 'Site ID (existing or newly created)' })
  siteId!: string;

  @ApiProperty({ description: 'True if a new site was created, false if linked to existing site' })
  isNewSite!: boolean;

  @ApiProperty({ description: 'Points awarded for this report (100 for new site, 50 for co-report)' })
  pointsAwarded!: number;
}
