import { ApiProperty } from '@nestjs/swagger';
import { ReportStatus } from '@prisma/client';

export class AdminReportListItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({
    description: 'Human-friendly report number for queue operations',
    example: 'R-01',
  })
  reportNumber!: string;

  @ApiProperty({
    description: 'Short descriptive title for the report',
    example: 'Illegal waste dump',
  })
  name!: string;

  @ApiProperty({
    description: 'High-level location label used in tables',
    example: 'Skopje',
  })
  location!: string;

  @ApiProperty({
    description: 'ISO timestamp when the report was created',
    example: '2025-10-23T09:15:00.000Z',
  })
  dateReportedAt!: string;

  @ApiProperty({ enum: ReportStatus })
  status!: ReportStatus;

  @ApiProperty({
    description: 'Whether this report is flagged as a potential duplicate',
    default: false,
  })
  isPotentialDuplicate!: boolean;

  @ApiProperty({
    description: 'Number of additional co-reporters attached to this report',
    default: 0,
  })
  coReporterCount!: number;
}

export class AdminReportListMetaDto {
  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  total!: number;
}

export class AdminReportListResponseDto {
  @ApiProperty({ type: () => [AdminReportListItemDto] })
  data!: AdminReportListItemDto[];

  @ApiProperty({ type: () => AdminReportListMetaDto })
  meta!: AdminReportListMetaDto;
}

export class AdminReportEvidenceDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  label!: string;

  @ApiProperty({ enum: ['image', 'video', 'document'] })
  kind!: 'image' | 'video' | 'document';

  @ApiProperty()
  sizeLabel!: string;

  @ApiProperty()
  uploadedAt!: string;

  @ApiProperty({ required: false })
  previewUrl?: string;

  @ApiProperty({ required: false })
  previewAlt?: string;
}

export class AdminReportTimelineEntryDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty()
  detail!: string;

  @ApiProperty()
  actor!: string;

  @ApiProperty()
  occurredAt!: string;

  @ApiProperty({ enum: ['neutral', 'success', 'warning', 'info'] })
  tone!: 'neutral' | 'success' | 'warning' | 'info';
}

export class AdminReportModerationMetaDto {
  @ApiProperty()
  queueLabel!: string;

  @ApiProperty()
  slaLabel!: string;

  @ApiProperty()
  assignedTeam!: string;
}

export class AdminReportMapPinDto {
  @ApiProperty()
  latitude!: number;

  @ApiProperty()
  longitude!: number;

  @ApiProperty()
  label!: string;
}

export class AdminReportDetailDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  reportNumber!: string;

  @ApiProperty({ enum: ReportStatus })
  status!: ReportStatus;

  @ApiProperty({ enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'] })
  priority!: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

  @ApiProperty()
  title!: string;

  @ApiProperty()
  description!: string;

  @ApiProperty()
  location!: string;

  @ApiProperty()
  submittedAt!: string;

  @ApiProperty()
  reporterAlias!: string;

  @ApiProperty({ enum: ['Bronze', 'Silver', 'Gold'] })
  reporterTrust!: 'Bronze' | 'Silver' | 'Gold';

  @ApiProperty({ type: () => [AdminReportEvidenceDto] })
  evidence!: AdminReportEvidenceDto[];

  @ApiProperty({ type: () => [AdminReportTimelineEntryDto] })
  timeline!: AdminReportTimelineEntryDto[];

  @ApiProperty({ type: () => AdminReportModerationMetaDto })
  moderation!: AdminReportModerationMetaDto;

  @ApiProperty({ type: () => AdminReportMapPinDto })
  mapPin!: AdminReportMapPinDto;

  @ApiProperty({
    description: 'Whether this report is flagged as a potential duplicate',
    default: false,
  })
  isPotentialDuplicate!: boolean;

  @ApiProperty({
    description: 'Additional reporters who also submitted this report',
    type: [String],
  })
  coReporters!: string[];

  @ApiProperty({
    required: false,
    description: 'Report number of the primary report this one is considered a potential duplicate of, if any',
  })
  potentialDuplicateOfReportNumber!: string | null;
}

