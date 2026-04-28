import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteStatus } from '../../prisma-client';

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
