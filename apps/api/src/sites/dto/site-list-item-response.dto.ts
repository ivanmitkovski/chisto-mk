import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteStatus } from '../../prisma-client';
import {
  VIEWER_RESOLUTION_STATUS_VALUES,
  type ViewerResolutionStatusDto,
} from './site-detail-response.dto';

export { VIEWER_RESOLUTION_STATUS_VALUES, type ViewerResolutionStatusDto };

/** One row in `GET /sites` feed (public contract; maps from service layer). */
export class SiteListItemResponseDto {
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
  reportCount!: number;

  @ApiProperty({ nullable: true })
  latestReportTitle!: string | null;

  @ApiProperty({ nullable: true })
  latestReportDescription!: string | null;

  @ApiProperty({ nullable: true })
  latestReportCategory!: string | null;

  @ApiProperty({ nullable: true })
  latestReportCreatedAt!: string | null;

  @ApiProperty({ nullable: true })
  latestReportNumber!: string | null;

  @ApiPropertyOptional({ type: [String] })
  latestReportMediaUrls?: string[];

  @ApiPropertyOptional({ type: [String], description: 'Canonical hero image from earliest approved report with media' })
  heroMediaUrls?: string[];

  @ApiPropertyOptional({ nullable: true })
  latestReportReporterName?: string | null;

  @ApiPropertyOptional({ nullable: true })
  latestReportReporterAvatarUrl?: string | null;

  @ApiPropertyOptional({ nullable: true })
  latestReportReporterId?: string | null;

  @ApiProperty()
  upvotesCount!: number;

  @ApiProperty()
  commentsCount!: number;

  @ApiProperty()
  sharesCount!: number;

  @ApiProperty()
  isUpvotedByMe!: boolean;

  @ApiProperty()
  isSavedByMe!: boolean;

  @ApiProperty({ enum: VIEWER_RESOLUTION_STATUS_VALUES })
  viewerResolutionStatus!: ViewerResolutionStatusDto;

  @ApiProperty()
  rankingScore!: number;

  @ApiProperty({ type: [String] })
  rankingReasons!: string[];

  @ApiPropertyOptional()
  rankingComponents?: Record<string, number>;

  @ApiPropertyOptional()
  distanceKm?: number;
}

export class SiteFeedListMetaResponseDto {
  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  total!: number;

  @ApiProperty({ nullable: true })
  nextCursor!: string | null;
}

export class SiteFeedListResponseDto {
  @ApiProperty({ type: [SiteListItemResponseDto] })
  data!: SiteListItemResponseDto[];

  @ApiProperty({ type: SiteFeedListMetaResponseDto })
  meta!: SiteFeedListMetaResponseDto;
}
