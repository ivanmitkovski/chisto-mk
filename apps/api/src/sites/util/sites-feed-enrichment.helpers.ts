import { SiteStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { ListSitesQueryDto, SiteFeedMode, SiteFeedSort } from '../dto/list-sites-query.dto';
import type { FeedSiteRow } from '../types/sites-feed-candidate.types';

type SiteBaseRow = Omit<FeedSiteRow, 'reports' | 'votes' | 'saves' | '_count' | 'heroReport'>;

export type FeedEnrichedRow = SiteBaseRow & {
  reportCount: number;
  latestReportTitle: string | null;
  latestReportDescription: string | null;
  latestReportCategory: string | null;
  latestReportCreatedAt: string | null;
  latestReportNumber: string | null;
  latestReportMediaUrls?: string[] | undefined;
  heroMediaUrls?: string[] | undefined;
  latestReportReporterName?: string | null | undefined;
  latestReportReporterAvatarUrl?: string | null | undefined;
  latestReportReporterId?: string | null | undefined;
  upvotesCount: number;
  commentsCount: number;
  savesCount: number;
  sharesCount: number;
  isUpvotedByMe: boolean;
  isSavedByMe: boolean;
  viewerResolutionStatus: 'none' | 'pending' | 'approved';
  rankingScore: number;
  rankingReasons: string[];
  rankingComponents?: Record<string, number> | undefined;
  distanceKm?: number | undefined;
};

export function sessionCategoryAffinity(category: string | null): number {
  if (!category) return 0;
  const categoryUpper = category.toUpperCase();
  if (categoryUpper.includes('WASTE')) return 0.9;
  if (categoryUpper.includes('AIR') || categoryUpper.includes('WATER')) return 0.75;
  return 0.5;
}

export function sessionStatusAffinity(status: SiteStatus): number {
  switch (status) {
    case 'VERIFIED':
    case 'IN_PROGRESS':
      return 0.85;
    case 'REPORTED':
      return 0.65;
    case 'CLEANUP_SCHEDULED':
      return 0.7;
    default:
      return 0.4;
  }
}

export function sortEnrichedRows(
  rows: FeedEnrichedRow[],
  rankedHybrid: boolean,
): FeedEnrichedRow[] {
  return [...rows].sort((a, b) => {
    if (rankedHybrid) {
      if (b.rankingScore !== a.rankingScore) return b.rankingScore - a.rankingScore;
      if ((a.distanceKm ?? Number.MAX_SAFE_INTEGER) !== (b.distanceKm ?? Number.MAX_SAFE_INTEGER)) {
        return (a.distanceKm ?? Number.MAX_SAFE_INTEGER) - (b.distanceKm ?? Number.MAX_SAFE_INTEGER);
      }
    } else if (b.rankingScore !== a.rankingScore) {
      return b.rankingScore - a.rankingScore;
    }
    if (b.createdAt.getTime() !== a.createdAt.getTime()) {
      return b.createdAt.getTime() - a.createdAt.getTime();
    }
    return b.id.localeCompare(a.id);
  });
}

export function mapToFeedResponseData(
  rows: FeedEnrichedRow[],
  query: ListSitesQueryDto,
) {
  return rows.map((row) => ({
    id: row.id,
    latitude: row.latitude,
    longitude: row.longitude,
    description: row.description,
    status: row.status,
    reportCount: row.reportCount,
    latestReportTitle: row.latestReportTitle,
    latestReportDescription: row.latestReportDescription,
    latestReportCategory: row.latestReportCategory,
    latestReportCreatedAt: row.latestReportCreatedAt,
    latestReportNumber: row.latestReportNumber,
    latestReportMediaUrls: row.latestReportMediaUrls,
    heroMediaUrls: row.heroMediaUrls,
    latestReportReporterName: row.latestReportReporterName,
    latestReportReporterAvatarUrl: row.latestReportReporterAvatarUrl,
    latestReportReporterId: row.latestReportReporterId,
    upvotesCount: row.upvotesCount,
    commentsCount: row.commentsCount,
    sharesCount: row.sharesCount,
    isUpvotedByMe: row.isUpvotedByMe,
    isSavedByMe: row.isSavedByMe,
    viewerResolutionStatus: row.viewerResolutionStatus,
    rankingScore: row.rankingScore,
    rankingReasons: row.rankingReasons,
    ...(query.explain ? { rankingComponents: row.rankingComponents } : {}),
    distanceKm: row.distanceKm,
  }));
}

export function isRankedHybrid(query: ListSitesQueryDto): boolean {
  return query.sort === SiteFeedSort.HYBRID && query.mode !== SiteFeedMode.LATEST;
}

/** Avoid full-table COUNT(*) on hot feed path; falls back when estimate unavailable. */
export async function approximateSiteCount(prisma: PrismaService, where: object): Promise<number> {
  try {
    const rows = await prisma.$queryRaw<Array<{ estimate: number }>>`
      SELECT COALESCE(reltuples, 0)::float AS estimate
      FROM pg_class
      WHERE relname = 'Site'
    `;
    const estimate = Math.max(0, Math.round(rows[0]?.estimate ?? 0));
    if (estimate > 0) return estimate;
  } catch {
    // fall through
  }
  return prisma.site.count({ where: where as never });
}
