import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteStatus } from '../../prisma-client';

export class SiteDetailReporterDto {
  @ApiProperty()
  firstName!: string;

  @ApiProperty()
  lastName!: string;

  @ApiProperty({ nullable: true })
  avatarUrl!: string | null;
}

export class SiteDetailCoReporterDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  reportedAt!: Date;

  @ApiProperty()
  reportId!: string;

  @ApiProperty()
  userId!: string;

  @ApiPropertyOptional({ type: () => SiteDetailReporterDto })
  user?: SiteDetailReporterDto | null;
}

export class SiteDetailReportResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  reportNumber!: number;

  @ApiProperty()
  siteId!: string;

  @ApiProperty()
  reporterId!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty({ nullable: true })
  description!: string | null;

  @ApiProperty({ type: [String] })
  mediaUrls!: string[];

  @ApiProperty()
  category!: string;

  @ApiProperty()
  severity!: string;

  @ApiProperty({ nullable: true })
  cleanupEffort!: string | null;

  @ApiProperty()
  status!: string;

  @ApiProperty({ nullable: true })
  moderatedAt!: Date | null;

  @ApiProperty({ nullable: true })
  moderationReason!: string | null;

  @ApiProperty({ nullable: true })
  moderatedById!: string | null;

  @ApiProperty({ nullable: true })
  potentialDuplicateOfId!: string | null;

  @ApiPropertyOptional({ type: () => SiteDetailReporterDto })
  reporter?: SiteDetailReporterDto | null;

  @ApiProperty({ type: [SiteDetailCoReporterDto] })
  coReporters!: SiteDetailCoReporterDto[];

  @ApiProperty()
  mergedDuplicateChildCount!: number;
}

export class SiteDetailEventResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty({ nullable: true })
  description!: string | null;

  @ApiProperty()
  scheduledAt!: Date;

  @ApiProperty()
  city!: string;

  @ApiProperty()
  participantCount!: number;

  @ApiProperty()
  maxParticipants!: number;

  @ApiProperty()
  status!: string;
}

/** Top-level `GET /sites/:id` contract. */
export class SiteDetailResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  latitude!: number;

  @ApiProperty()
  longitude!: number;

  @ApiProperty({ nullable: true })
  description!: string | null;

  @ApiProperty({ enum: SiteStatus })
  status!: SiteStatus;

  @ApiProperty()
  upvotesCount!: number;

  @ApiProperty()
  commentsCount!: number;

  @ApiProperty()
  savesCount!: number;

  @ApiProperty()
  sharesCount!: number;

  @ApiProperty()
  isUpvotedByMe!: boolean;

  @ApiProperty()
  isSavedByMe!: boolean;

  @ApiProperty({ type: [String] })
  coReporterNames!: string[];

  @ApiProperty()
  mergedDuplicateChildCountTotal!: number;

  @ApiPropertyOptional({ type: [SiteDetailReportResponseDto] })
  reports?: SiteDetailReportResponseDto[];

  @ApiPropertyOptional()
  hasMoreReports?: boolean;

  @ApiPropertyOptional({ type: [SiteDetailEventResponseDto] })
  events?: SiteDetailEventResponseDto[];

  @ApiPropertyOptional()
  hasMoreEvents?: boolean;
}
