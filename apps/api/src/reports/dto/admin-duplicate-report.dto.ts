import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReportStatus } from '@prisma/client';
import { ArrayNotEmpty, ArrayUnique, IsArray, IsOptional, IsString, MaxLength } from 'class-validator';

export class AdminDuplicateReportItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({
    description: 'Human-friendly report number for queue operations',
    example: 'R-25-ABCD',
  })
  reportNumber!: string;

  @ApiProperty({
    description: 'Short descriptive title for the report',
    example: 'Illegal waste dump',
  })
  title!: string;

  @ApiProperty({
    description: 'High-level location label used in tables',
    example: 'Skopje',
  })
  location!: string;

  @ApiProperty({
    description: 'ISO timestamp when the report was created',
    example: '2025-10-23T09:15:00.000Z',
  })
  submittedAt!: string;

  @ApiProperty({ enum: ReportStatus })
  status!: ReportStatus;

  @ApiProperty({
    description: 'Number of additional co-reporters attached to this report',
    default: 0,
  })
  coReporterCount!: number;

  @ApiProperty({
    description: 'Number of media assets attached to this report',
    default: 0,
  })
  mediaCount!: number;
}

export class AdminDuplicateReportGroupDto {
  @ApiProperty({ type: () => AdminDuplicateReportItemDto })
  primaryReport!: AdminDuplicateReportItemDto;

  @ApiProperty({ type: () => [AdminDuplicateReportItemDto] })
  duplicateReports!: AdminDuplicateReportItemDto[];

  @ApiProperty({
    description: 'Total reports in the duplicate group including the primary report',
    example: 3,
  })
  totalReports!: number;
}

export class AdminDuplicateReportGroupsMetaDto {
  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  total!: number;
}

export class AdminDuplicateReportGroupsResponseDto {
  @ApiProperty({ type: () => [AdminDuplicateReportGroupDto] })
  data!: AdminDuplicateReportGroupDto[];

  @ApiProperty({ type: () => AdminDuplicateReportGroupsMetaDto })
  meta!: AdminDuplicateReportGroupsMetaDto;
}

export class MergeDuplicateReportsDto {
  @ApiProperty({
    description: 'IDs of child duplicate reports to merge into the primary report',
    type: [String],
  })
  @IsArray()
  @ArrayNotEmpty()
  @ArrayUnique()
  @IsString({ each: true })
  childReportIds!: string[];

  @ApiPropertyOptional({
    description: 'Optional human-readable moderation reason',
    maxLength: 500,
    example: 'Merged duplicate reports after manual verification.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

export class MergeDuplicateReportsResponseDto {
  @ApiProperty()
  primaryReportId!: string;

  @ApiProperty()
  mergedChildCount!: number;

  @ApiProperty()
  mergedMediaCount!: number;

  @ApiProperty()
  mergedCoReporterCount!: number;

  @ApiProperty({ enum: ReportStatus })
  primaryStatus!: ReportStatus;
}
