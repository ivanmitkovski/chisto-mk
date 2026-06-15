import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteResolutionStatus } from '../../../prisma-client';

export class SiteResolutionSubmitterDto {
  @ApiPropertyOptional({ nullable: true })
  displayLabel!: string | null;

  @ApiProperty()
  isSelf!: boolean;

  @ApiProperty()
  isDeleted!: boolean;

  @ApiProperty()
  isAnonymous!: boolean;
}

export class SiteResolutionResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  siteId!: string;

  @ApiProperty({ enum: SiteResolutionStatus })
  status!: SiteResolutionStatus;

  @ApiProperty({ type: [String] })
  mediaUrls!: string[];

  @ApiPropertyOptional({ nullable: true })
  note!: string | null;

  @ApiProperty()
  isReporterSubmission!: boolean;

  @ApiProperty()
  createdAt!: string;

  @ApiPropertyOptional({ nullable: true })
  moderatedAt!: string | null;

  @ApiPropertyOptional({ type: SiteResolutionSubmitterDto, nullable: true })
  submitter!: SiteResolutionSubmitterDto | null;
}

export class SiteResolutionListResponseDto {
  @ApiProperty({ type: [SiteResolutionResponseDto] })
  data!: SiteResolutionResponseDto[];

  @ApiProperty()
  meta!: { total: number };
}
