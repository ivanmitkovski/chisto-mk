import { Injectable } from '@nestjs/common';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { distanceInMeters } from '../../common/utils/distance';
import { ObservabilityStore } from '../../observability/observability.store';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import { ListSitesQueryDto, SiteFeedGeoScope, SiteFeedMode, SiteFeedSort } from '../dto/list-sites-query.dto';
import { FeedRankingService, RankingInput } from './feed-ranking.service';
import { FeedV2Service } from '../feed/feed-v2.service';
import {
  decodeFeedCursor,
  encodeHybridFeedCursor,
  encodeRankedFeedCursor,
  isAfterRankedCursor,
} from '../util/sites-feed-cursor.util';
import { applyDiversityRerank } from '../util/sites-feed-diversity.util';
import type { FeedSiteRow, SitesFeedCandidateBundle } from '../types/sites-feed-candidate.types';
import { SitesFeedCacheService } from './sites-feed-cache.service';
import { SitesFeedPreferencesService } from './sites-feed-preferences.service';
import { SiteCommentsCountService } from './site-comments-count.service';
import { mapWithConcurrency } from '../util/sites-feed-query-async.util';
import { applyBatchSignedMediaToRows } from '../util/sites-feed-media-sign.util';
import type { SitesFeedListResult } from '../types/sites-feed.types';
import {
  approximateSiteCount,
  type FeedEnrichedRow,
  isRankedHybrid,
  mapToFeedResponseData,
  sessionCategoryAffinity,
  sessionStatusAffinity,
  sortEnrichedRows,
} from '../util/sites-feed-enrichment.helpers';
import {
  discoveryRankingRadiusKm,
  resolveFeedGeoScope,
} from '../util/sites-feed-geo-scope.util';
import { resolveActorIdentity } from '../../common/projections/public-identity.projection';
import { PrismaService } from '../../prisma/prisma.service';
import { SiteResolutionQueryService } from '../resolutions/services/site-resolution-query.service';
import { viewerResolutionStatusForSite } from '../resolutions/util/viewer-resolution-status';

@Injectable()
export class SitesFeedEnrichmentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly feedRanking: FeedRankingService,
    private readonly feedV2: FeedV2Service,
    private readonly feedCache: SitesFeedCacheService,
    private readonly preferences: SitesFeedPreferencesService,
    private readonly siteCommentsCount: SiteCommentsCountService,
    private readonly siteResolutionQuery: SiteResolutionQueryService,
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
    const geoScope = resolveFeedGeoScope(query);
    const rankingRadiusKm =
      geoScope === SiteFeedGeoScope.DISCOVERY
        ? discoveryRankingRadiusKm(query.radiusKm)
        : query.radiusKm;
    const rankedHybrid = isRankedHybrid(query);
    const cursorState = decodeFeedCursor(query.cursor, rankedHybrid);

    const enrichedRows = await mapWithConcurrency(sites, 10, async (site) =>
      this.enrichSiteRow(site, query, {
        hasGeo,
        rankingRadiusKm,
        velocityBySite,
        duplicateTitleCounts,
      }),
    );

    const enrichedRowsSigned = await applyBatchSignedMediaToRows(enrichedRows, (unique) =>
      this.reportsUploadService.signUrls(unique),
    );

    const feedVariant = await this.feedV2.resolveVariant(user);
    if (user?.userId) this.preferences.setVariantMemo(user.userId, feedVariant);

    let enriched: FeedEnrichedRow[] = this.preferences.applyUserPreferences(
      enrichedRowsSigned as FeedEnrichedRow[],
      user,
    ) as FeedEnrichedRow[];

    if (
      geoScope !== SiteFeedGeoScope.DISCOVERY &&
      hasGeo &&
      query.lat != null &&
      query.lng != null
    ) {
      const radiusMeters = (query.radiusKm ?? 10) * 1000;
      enriched = enriched.filter((s) => (s.distanceKm ?? 0) * 1000 <= radiusMeters);
    }
    enriched = sortEnrichedRows(enriched, rankedHybrid);
    enriched = (await this.feedV2.rerankRows(
      enriched as Parameters<FeedV2Service['rerankRows']>[0],
      query,
      user,
      feedVariant,
    )) as FeedEnrichedRow[];
    enriched = applyDiversityRerank(
      enriched as Parameters<typeof applyDiversityRerank>[0],
      query,
    ) as FeedEnrichedRow[];
    if (cursorState?.hybrid != null) {
      enriched = enriched.filter((row) => isAfterRankedCursor(row, cursorState.hybrid!));
    }

    const total = query.cursor ? 0 : await approximateSiteCount(this.prisma, where);
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

    const responseData = mapToFeedResponseData(data, query);
    if (user?.userId) {
      const [visibleCounts, resolutionStatusBySite] = await Promise.all([
        this.siteCommentsCount.countVisibleBatch(
          data.map((row) => row.id),
          user,
        ),
        this.siteResolutionQuery.getViewerStatusBySiteIds(
          user.userId,
          data.map((row) => row.id),
        ),
      ]);
      for (const item of responseData) {
        const visible = visibleCounts.get(item.id);
        if (visible != null) {
          item.commentsCount = visible;
        }
        item.viewerResolutionStatus = viewerResolutionStatusForSite(
          resolutionStatusBySite,
          item.id,
        );
      }
    } else {
      for (const item of responseData) {
        item.viewerResolutionStatus = 'none';
      }
    }
    const response: SitesFeedListResult = {
      data: responseData as unknown as SitesFeedListResult['data'],
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

  private async enrichSiteRow(
    site: FeedSiteRow,
    query: ListSitesQueryDto,
    ctx: {
      hasGeo: boolean;
      rankingRadiusKm: number;
      velocityBySite: Map<string, number>;
      duplicateTitleCounts: Map<string, number>;
    },
  ): Promise<FeedEnrichedRow> {
    const { reports, votes, saves, _count, heroReport, ...siteBase } = site;
    const firstReport = reports[0];
    const heroUrls =
      heroReport?.mediaUrls?.filter((url) => typeof url === 'string' && url.trim().length > 0) ??
      [];
    const latestMediaUrls = firstReport?.mediaUrls?.length ? firstReport.mediaUrls : undefined;
    let latestReportReporterName: string | null = null;
    let latestReportReporterAvatarUrl: string | null = null;
    let latestReportReporterId: string | null = null;
    const feedRep = firstReport?.reporter;
    if (feedRep) {
      latestReportReporterId = feedRep.id;
      const identity = resolveActorIdentity(feedRep, { actorUserId: feedRep.id });
      latestReportReporterName = identity.isDeleted ? null : (identity.displayName ?? null);
      latestReportReporterAvatarUrl = await this.reportsUploadService.signPrivateObjectKey(
        feedRep.avatarObjectKey,
      );
    }
    const latestReportDate = firstReport?.createdAt ?? siteBase.createdAt;
    const distanceKm =
      ctx.hasGeo && query.lat != null && query.lng != null
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
      ...(ctx.hasGeo ? { radiusKm: ctx.rankingRadiusKm } : {}),
      reportCount: _count.reports,
      sessionCategoryAffinity: sessionCategoryAffinity(firstReport?.category ?? null),
      sessionGeoAffinity:
        distanceKm != null && ctx.rankingRadiusKm > 0
          ? Math.max(0, 1 - distanceKm / ctx.rankingRadiusKm)
          : 0,
      sessionStatusAffinity: sessionStatusAffinity(siteBase.status),
      engagementVelocity: Math.min(1, (ctx.velocityBySite.get(siteBase.id) ?? 0) / 30),
      duplicateContentPenalty: Math.min(
        0.15,
        Math.max(
          0,
          ((ctx.duplicateTitleCounts.get(firstReport?.title?.trim().toLowerCase() ?? '') ?? 1) -
            1) *
            0.04,
        ),
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
      latestReportMediaUrls: latestMediaUrls,
      heroMediaUrls: heroUrls.length > 0 ? heroUrls : undefined,
      latestReportReporterName,
      latestReportReporterAvatarUrl,
      latestReportReporterId,
      isUpvotedByMe: Array.isArray(votes) && votes.length > 0,
      isSavedByMe: Array.isArray(saves) && saves.length > 0,
      viewerResolutionStatus: 'none' as const,
      rankingScore: rankingDetail.score,
      rankingReasons: rankingDetail.reasonCodes,
      ...(query.explain ? { rankingComponents: rankingDetail.components } : {}),
      distanceKm,
    };
  }
}
