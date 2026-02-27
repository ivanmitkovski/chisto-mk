import { ApiProperty } from '@nestjs/swagger';
import { ReportStatus } from '@prisma/client';

export class UserReportListItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({
    description: 'Human-readable report number, e.g. R-25-ABCD',
  })
  reportNumber!: string;

  @ApiProperty({
    description: 'Short title or description of the reported site',
  })
  title!: string;

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
}

