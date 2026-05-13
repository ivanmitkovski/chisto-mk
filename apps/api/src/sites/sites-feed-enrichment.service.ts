import { Injectable } from '@nestjs/common';
import { SiteStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { distanceInMeters } from '../common/utils/distance';
import { ObservabilityStore } from '../observability/observability.store';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { ListSitesQueryDto, SiteFeedMode, SiteFeedSort } from './dto/list-sites-query.dto';
import { FeedRankingService, RankingInput } from './feed-ranking.service';
import { FeedV2Service } from './feed/feed-v2.service';
import {
  decodeFeedCursor,
  encodeHybridFeedCursor,
  encodeRankedFeedCursor,
  isAfterRankedCursor,
} from './sites-feed-cursor.util';
import { applyDiversityRerank } from './sites-feed-diversity.util';
import type { FeedSiteRow, SitesFeedCandidateBundle } from './sites-feed-candidate.types';
import { SitesFeedCacheService } from './sites-feed-cache.service';
import { SitesFeedPreferencesService } from './sites-feed-preferences.service';
import { mapWithConcurrency } from './sites-feed-query-async.util';
import type { SitesFeedListResult } from './sites-feed.types';

@Injectable()
export class SitesFeedEnrichmentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly feedRanking: FeedRankingService,
    private readonly feedV2: FeedV2Service,
    private readonly feedCache: SitesFeedCacheService,
    private readonly preferences: SitesFeedPreferencesService,
  ) {}

  async buildFeedListResponse(
    bundle: SitesFeedCandidateBundle,
    query: ListSitesQueryDto,
    user: AuthenticatedUser | undefined,
    opts: { startedAt: number; nowMs: number; cacheKey: string },
  ): Promise<SitesFeedListResult> {
    const { startedAt, nowMs, cacheKey } = opts;
    const { sites, velocityBySite, duplicateTitleCounts, where } = bundle;

    const hasGeo = query.lat != null && query.lng != null;
    const rankedHybrid = query.sort === SiteFeedSort.HYBRID && query.mode !== SiteFeedMode.LATEST;
    const cursorState = decodeFeedCursor(query.cursor, rankedHybrid);

    type SiteEnriched = Omit<FeedSiteRow, 'reports' | 'votes' | 'saves' | '_count'> & {
      reportCount: number;
      latestReportTitle: string | null;
      latestReportDescription: string | null;
      latestReportCategory: string | null;
      latestReportCreatedAt: string | null;
      latestReportNumber: string | null;
      latestReportMediaUrls?: string[];
      latestReportReporterName?: string | null;
      latestReportReporterAvatarUrl?: string | null;
      latestReportReporterId?: string | null;
      upvotesCount: number;
      commentsCount: number;
      savesCount: number;
      sharesCount: number;
      isUpvotedByMe: boolean;
      isSavedByMe: boolean;
      rankingScore: number;
      rankingReasons: string[];
      rankingComponents?: Record<string, number>;
      distanceKm?: number;
    };

    const enrichedRows = await mapWithConcurrency(sites, 10, async (site) => {
      const { reports, votes, saves, _count, ...siteBase } = site;
      const firstReport = reports[0];
      const mediaUrls = firstReport?.mediaUrls?.length
        ? await this.reportsUploadService.signUrls(firstReport.mediaUrls)
        : undefined;
      let latestReportReporterName: string | null = null;
      let latestReportReporterAvatarUrl: string | null = null;
      let latestReportReporterId: string | null = null;
      const feedRep = firstReport?.reporter;
      if (feedRep) {
        latestReportReporterId = feedRep.id;
        const nm = `${feedRep.firstName ?? ''} ${feedRep.lastName ?? ''}`.trim();
        latestReportReporterName = nm.length > 0 ? nm : null;
        latestReportReporterAvatarUrl = await this.reportsUploadService.signPrivateObjectKey(
          feedRep.avatarObjectKey,
        );
      }
      const latestReportDate = firstReport?.createdAt ?? siteBase.createdAt;
      const distanceKm =
        hasGeo && query.lat != null && query.lng != null
          ? distanceInMeters(query.lat, query.lng, site.latitude, site.longitude) / 1000
          : undefined;
      const rankingInput: RankingInput = {
        siteId: siteBase.id,
        createdAt: latestReportDate,
        upvotesCount: siteBase.upvotesCount,
        commentsCount: siteBase.commentsCount,
        savesCount: siteBase.savesCount,
        sharesCount: siteBase.sharesCount,
        status: siteBase.status,
        ...(distanceKm != null ? { distanceKm } : {}),
        ...(hasGeo ? { radiusKm: query.radiusKm } : {}),
        reportCount: _count.reports,
        sessionCategoryAffinity: this.sessionCategoryAffinity(firstReport?.category ?? null),
        sessionGeoAffinity:
          distanceKm != null && query.radiusKm > 0 ? Math.max(0, 1 - distanceKm / query.radiusKm) : 0,
        sessionStatusAffinity: this.sessionStatusAffinity(siteBase.status),
        engagementVelocity: Math.min(1, (velocityBySite.get(siteBase.id) ?? 0) / 30),
        duplicateContentPenalty: Math.min(
          0.15,
          Math.max(0, ((duplicateTitleCounts.get(firstReport?.title?.trim().toLowerCase() ?? '') ?? 1) - 1) * 0.04),
        ),
        policyEligibility: siteBase.status === 'DISPUTED' ? 0.35 : 1,
      };
      const rankingDetail =
        query.sort === SiteFeedSort.HYBRID && query.mode !== SiteFeedMode.LATEST
          ? this.feedRanking.scoreDetailed(rankingInput)
          : {
              score: latestReportDate.getTime(),
              reasonCodes: ['latest_mode'],
              components: {
                recency: 1,
                engagement: 0,
                distance: 0,
                trust: 1,
                antiGamingPenalty: 0,
                explorationBoost: 0,
                sessionBoost: 0,
                jitter: 0,
              },
            };
      return {
        ...siteBase,
        reportCount: _count.reports,
        latestReportTitle: firstReport?.title ?? null,
        latestReportDescription: firstReport?.description ?? null,
        latestReportCategory: firstReport?.category ?? null,
        latestReportCreatedAt: firstReport?.createdAt?.toISOString() ?? null,
        latestReportNumber: firstReport?.reportNumber ?? null,
        latestReportMediaUrls: mediaUrls,
        latestReportReporterName,
        latestReportReporterAvatarUrl,
        latestReportReporterId,
        isUpvotedByMe: Array.isArray(votes) && votes.length > 0,
        isSavedByMe: Array.isArray(saves) && saves.length > 0,
        rankingScore: rankingDetail.score,
        rankingReasons: rankingDetail.reasonCodes,
        ...(query.explain ? { rankingComponents: rankingDetail.components } : {}),
        distanceKm,
      } as SiteEnriched;
    });
    const feedVariant = await this.feedV2.resolveVariant(user);
    if (user?.userId) this.preferences.setVariantMemo(user.userId, feedVariant);

    let enriched = enrichedRows;
    enriched = this.preferences.applyUserPreferences(enriched, user);

    if (hasGeo && query.lat != null && query.lng != null) {
      const radiusMeters = (query.radiusKm ?? 10) * 1000;
      enriched = enriched.filter((s) => (s.distanceKm ?? 0) * 1000 <= radiusMeters);
    }
    enriched = enriched.sort((a, b) => {
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
    enriched = await this.feedV2.rerankRows(enriched, query, user, feedVariant);
    enriched = applyDiversityRerank(enriched, query);
    if (cursorState?.hybrid != null) {
      enriched = enriched.filter((row) => isAfterRankedCursor(row, cursorState.hybrid!));
    }

    const total = query.cursor ? 0 : await this.prisma.site.count({ where });
    const skip = query.cursor ? 0 : (query.page - 1) * query.limit;
    const data = enriched.slice(skip, skip + query.limit);
    const nextCursor =
      data.length === query.limit
        ? rankedHybrid
          ? encodeHybridFeedCursor(
              data[data.length - 1].rankingScore,
              data[data.length - 1].id,
              data[data.length - 1].createdAt,
            )
          : encodeRankedFeedCursor(data[data.length - 1].rankingScore, data[data.length - 1].id)
        : null;

    const responseData = data.map((row) => ({
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
      latestReportReporterName: row.latestReportReporterName,
      latestReportReporterAvatarUrl: row.latestReportReporterAvatarUrl,
      latestReportReporterId: row.latestReportReporterId,
      upvotesCount: row.upvotesCount,
      commentsCount: row.commentsCount,
      sharesCount: row.sharesCount,
      isUpvotedByMe: row.isUpvotedByMe,
      isSavedByMe: row.isSavedByMe,
      rankingScore: row.rankingScore,
      rankingReasons: row.rankingReasons,
      ...(query.explain ? { rankingComponents: row.rankingComponents } : {}),
      distanceKm: row.distanceKm,
    }));
    const response: SitesFeedListResult = {
      data: responseData as typeof data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        nextCursor,
      },
      feedVariant,
    };
    const duplicateCount = new Set(data.map((row) => row.id)).size !== data.length;
    if (duplicateCount) {
      ObservabilityStore.recordFeedPaginationContinuityIssue();
    }
    ObservabilityStore.recordFeedReasonCodes(data.flatMap((row) => row.rankingReasons ?? []));
    this.feedCache.set(
      cacheKey,
      response,
      data.map((row) => row.id),
      nowMs,
    );
    ObservabilityStore.recordFeedRequest({
      durationMs: Date.now() - startedAt,
      candidatePoolSize: enriched.length,
      cacheHit: false,
    });
    return response;
  }

  private sessionCategoryAffinity(category: string | null): number {
    if (!category) return 0;
    const categoryUpper = category.toUpperCase();
    if (categoryUpper.includes('WASTE')) return 0.9;
    if (categoryUpper.includes('AIR') || categoryUpper.includes('WATER')) return 0.75;
    return 0.5;
  }

  private sessionStatusAffinity(status: SiteStatus): number {
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
}
