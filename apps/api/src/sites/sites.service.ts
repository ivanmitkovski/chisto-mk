import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Prisma, ReportStatus, Site, SiteShareChannel, SiteStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { SiteEventsService } from '../admin-events/site-events.service';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { distanceInMeters } from '../common/utils/distance';
import { ObservabilityStore } from '../observability/observability.store';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { CreateSiteDto } from './dto/create-site.dto';
import { ListSitesMapQueryDto } from './dto/list-sites-map-query.dto';
import { ListSiteCommentsQueryDto } from './dto/list-site-comments-query.dto';
import { SiteCommentsSort } from './dto/list-site-comments-query.dto';
import { ListSiteMediaQueryDto } from './dto/list-site-media-query.dto';
import { ListSitesQueryDto, SiteFeedMode, SiteFeedSort } from './dto/list-sites-query.dto';
import { CreateSiteCommentDto } from './dto/create-site-comment.dto';
import { ShareSiteDto } from './dto/share-site.dto';
import { SubmitFeedFeedbackDto } from './dto/submit-feed-feedback.dto';
import { TrackFeedEventDto } from './dto/track-feed-event.dto';
import { UpdateSiteCommentDto } from './dto/update-site-comment.dto';
import { UpdateSiteStatusDto } from './dto/update-site-status.dto';
import { FeedRankingService, RankingInput } from './feed-ranking.service';
import { SiteEngagementService } from './site-engagement.service';

type SiteWithReportsAndEvents = Prisma.SiteGetPayload<{
  include: { reports: true; events: true };
}>;

type FeedSiteRow = Prisma.SiteGetPayload<{
  include: {
    reports: {
      orderBy: { createdAt: 'desc' };
      take: 1;
      select: {
        title: true;
        description: true;
        mediaUrls: true;
        category: true;
        createdAt: true;
        reportNumber: true;
        reporter: {
          select: { id: true; firstName: true; lastName: true; avatarObjectKey: true };
        };
      };
    };
    votes: { where: { userId: string }; select: { id: true }; take: 1 } | false;
    saves: { where: { userId: string }; select: { id: true }; take: 1 } | false;
    _count: { select: { reports: true } };
  };
}>;

type MapSiteRow = Prisma.SiteGetPayload<{
  select: {
    id: true;
    latitude: true;
    longitude: true;
    address: true;
    description: true;
    status: true;
    createdAt: true;
    updatedAt: true;
    upvotesCount: true;
    commentsCount: true;
    savesCount: true;
    sharesCount: true;
    _count: { select: { reports: true } };
    reports: {
      orderBy: { createdAt: 'desc' };
      take: 1;
      select: {
        title: true;
        description: true;
        mediaUrls: true;
        category: true;
        createdAt: true;
        reportNumber: true;
      };
    };
  };
}>;

type MapSiteLiteRow = Prisma.SiteGetPayload<{
  select: {
    id: true;
    latitude: true;
    longitude: true;
    address: true;
    description: true;
    status: true;
    createdAt: true;
    updatedAt: true;
    reports: {
      orderBy: { createdAt: 'desc' };
      take: 1;
      select: { mediaUrls: true };
    };
  };
}>;

/** JSON row shape for GET /sites/map (full and lite payloads share this envelope). */
type MapListApiRow = Site & {
  reportCount: number;
  latestReportTitle: string | null;
  latestReportDescription: string | null;
  latestReportCategory: string | null;
  latestReportCreatedAt: string | null;
  latestReportNumber: string | null;
  latestReportMediaUrls?: string[];
  upvotesCount: number;
  commentsCount: number;
  savesCount: number;
  sharesCount: number;
  distanceKm?: number;
};

const MAP_SITE_LITE_SELECT = {
  id: true,
  latitude: true,
  longitude: true,
  address: true,
  description: true,
  status: true,
  createdAt: true,
  updatedAt: true,
  reports: {
    orderBy: { createdAt: 'desc' },
    take: 1,
    select: { mediaUrls: true },
  },
} as const;

export type SiteCommentTreeNode = {
  id: string;
  parentId: string | null;
  body: string;
  createdAt: string;
  authorId: string;
  authorName: string;
  likesCount: number;
  isLikedByMe: boolean;
  replies: SiteCommentTreeNode[];
  repliesCount: number;
};

const MAP_SITE_FIND_SELECT = {
  id: true,
  latitude: true,
  longitude: true,
  address: true,
  description: true,
  status: true,
  createdAt: true,
  updatedAt: true,
  upvotesCount: true,
  commentsCount: true,
  savesCount: true,
  sharesCount: true,
  _count: { select: { reports: true } },
  reports: {
    orderBy: { createdAt: 'desc' },
    take: 1,
    select: {
      title: true,
      description: true,
      mediaUrls: true,
      category: true,
      createdAt: true,
      reportNumber: true,
    },
  },
} as const;

const ALLOWED_SITE_STATUS_TRANSITIONS: Record<SiteStatus, SiteStatus[]> = {
  REPORTED: ['VERIFIED', 'DISPUTED'],
  VERIFIED: ['CLEANUP_SCHEDULED', 'DISPUTED'],
  CLEANUP_SCHEDULED: ['IN_PROGRESS', 'DISPUTED'],
  IN_PROGRESS: ['CLEANED', 'DISPUTED'],
  CLEANED: ['DISPUTED'],
  DISPUTED: ['REPORTED', 'VERIFIED'],
};

@Injectable()
export class SitesService {
  /** Horizons presigned map thumbnails before AWS URL expiry (~1h); client refreshes map data. */
  private static readonly MAP_SIGNED_MEDIA_CLIENT_BUFFER_MS = 55 * 60 * 1000;

  private readonly feedCacheTtlMs = 15_000;
  private readonly mapCacheTtlMs = 4_000;
  private readonly feedQueryTimeoutMs = 5_000;
  private readonly feedResponseCache = new Map<
    string,
    {
      cachedAt: number;
      value: {
        data: Array<
          Site & {
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
          }
        >;
        meta: { page: number; limit: number; total: number; nextCursor?: string | null };
      };
    }
  >();
  private readonly feedCacheSiteIndex = new Map<string, Set<string>>();
  private readonly mapResponseCache = new Map<
    string,
    {
      cachedAt: number;
      value: {
        data: Array<
          Site & {
            reportCount: number;
            latestReportTitle: string | null;
            latestReportDescription: string | null;
            latestReportCategory: string | null;
            latestReportCreatedAt: string | null;
            latestReportNumber: string | null;
            latestReportMediaUrls?: string[];
            upvotesCount: number;
            commentsCount: number;
            savesCount: number;
            sharesCount: number;
            distanceKm?: number;
          }
        >;
        meta: { signedMediaExpiresAt: string };
      };
    }
  >();
  private readonly mapCacheSiteIndex = new Map<string, Set<string>>();
  /** Cached: does this DB report the postgis extension (map queries can use ST_DWithin / ST_Within). */
  private postgisMapSupport: boolean | null = null;
  private readonly feedUserPreferences = new Map<
    string,
    {
      hiddenSiteIds: Set<string>;
      mutedCategories: Map<string, number>;
      seenSiteIds: Map<string, number>;
      updatedAt: number;
    }
  >();

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly siteEventsService: SiteEventsService,
    private readonly feedRanking: FeedRankingService,
    private readonly siteEngagement: SiteEngagementService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async create(dto: CreateSiteDto): Promise<Site> {
    const site = await this.prisma.site.create({
      data: {
        latitude: dto.latitude,
        longitude: dto.longitude,
        description: dto.description ?? null,
      },
    });
    this.invalidateFeedCache('site_created');
    this.invalidateMapCache('site_created');
    this.siteEventsService.emitSiteCreated(site.id, {
      status: site.status,
      latitude: site.latitude,
      longitude: site.longitude,
      updatedAt: site.updatedAt,
    });
    return site;
  }

  async findAll(query: ListSitesQueryDto, user?: AuthenticatedUser): Promise<{
    data: Array<
      Site & {
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
      }
    >;
    meta: { page: number; limit: number; total: number; nextCursor?: string | null };
  }> {
    const startedAt = Date.now();
    const cacheKey = this.buildFeedCacheKey(query, user);
    const cached = this.feedResponseCache.get(cacheKey);
    const nowMs = Date.now();
    if (cached && nowMs - cached.cachedAt <= this.feedCacheTtlMs) {
      ObservabilityStore.recordFeedRequest({
        durationMs: Date.now() - startedAt,
        candidatePoolSize: cached.value.data.length,
        cacheHit: true,
      });
      return cached.value;
    }
    if ((query.lat != null) !== (query.lng != null)) {
      throw new BadRequestException({
        code: 'INVALID_GEO_QUERY',
        message: 'Both lat and lng must be provided together.',
      });
    }

    const where: Prisma.SiteWhereInput = query.status
      ? { status: query.status }
      : {};

    const hasGeo = query.lat != null && query.lng != null;
    if (hasGeo) {
      const radiusMeters = (query.radiusKm ?? 10) * 1000;
      const metersPerDegreeLat = 111_320;
      const deltaLat = radiusMeters / metersPerDegreeLat;
      const metersPerDegreeLng =
        Math.cos((query.lat! * Math.PI) / 180) * metersPerDegreeLat ||
        metersPerDegreeLat;
      const deltaLng = radiusMeters / metersPerDegreeLng;

      where.latitude = {
        gte: query.lat! - deltaLat,
        lte: query.lat! + deltaLat,
      };
      where.longitude = {
        gte: query.lng! - deltaLng,
        lte: query.lng! + deltaLng,
      };
    }

    const rankedHybrid = query.sort === SiteFeedSort.HYBRID && query.mode !== SiteFeedMode.LATEST;
    const cursorState = this.decodeFeedCursor(query.cursor, rankedHybrid);
    const cursorClause = cursorState?.dbClause ?? null;
    const feedWhere: Prisma.SiteWhereInput = cursorClause ? { AND: [where, cursorClause] } : where;
    const candidateLimit = Math.min(300, Math.max(query.limit * 6, query.limit));
    let sites: FeedSiteRow[];
    try {
      sites = await this.withTimeout(
        this.prisma.site.findMany({
        where: feedWhere,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: candidateLimit,
        include: {
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: {
            title: true,
            description: true,
            mediaUrls: true,
            category: true,
            createdAt: true,
            reportNumber: true,
            reporter: {
              select: { id: true, firstName: true, lastName: true, avatarObjectKey: true },
            },
          },
        },
        votes: user
          ? {
              where: { userId: user.userId },
              select: { id: true },
              take: 1,
            }
          : false,
        saves: user
          ? {
              where: { userId: user.userId },
              select: { id: true },
              take: 1,
            }
          : false,
        _count: { select: { reports: true } },
        },
      }),
        this.feedQueryTimeoutMs,
        'Feed query timed out',
      );
    } catch (error) {
      if (cached) {
        ObservabilityStore.recordFeedRequest({
          durationMs: Date.now() - startedAt,
          candidatePoolSize: cached.value.data.length,
          cacheHit: true,
        });
        return cached.value;
      }
      throw error;
    }
    const siteIds = sites.map((s) => s.id);
    const recentCutoff = new Date(Date.now() - 2 * 60 * 60 * 1000);
    const canGroupVelocity =
      siteIds.length > 0 &&
      typeof (this.prisma as unknown as { siteVote?: { groupBy?: unknown } }).siteVote?.groupBy ===
        'function' &&
      typeof (this.prisma as unknown as { siteSave?: { groupBy?: unknown } }).siteSave?.groupBy ===
        'function' &&
      typeof (this.prisma as unknown as { siteShareEvent?: { groupBy?: unknown } }).siteShareEvent
        ?.groupBy === 'function';
    const [recentVotes, recentSaves, recentShares] = canGroupVelocity
      ? await Promise.all([
          this.prisma.siteVote.groupBy({
            by: ['siteId'],
            where: { siteId: { in: siteIds }, createdAt: { gte: recentCutoff } },
            _count: { _all: true },
          }),
          this.prisma.siteSave.groupBy({
            by: ['siteId'],
            where: { siteId: { in: siteIds }, createdAt: { gte: recentCutoff } },
            _count: { _all: true },
          }),
          this.prisma.siteShareEvent.groupBy({
            by: ['siteId'],
            where: { siteId: { in: siteIds }, createdAt: { gte: recentCutoff } },
            _count: { _all: true },
          }),
        ])
      : [[], [], []];
    const velocityBySite = new Map<string, number>();
    for (const row of recentVotes) {
      velocityBySite.set(row.siteId, (velocityBySite.get(row.siteId) ?? 0) + row._count._all);
    }
    for (const row of recentSaves) {
      velocityBySite.set(row.siteId, (velocityBySite.get(row.siteId) ?? 0) + row._count._all * 1.4);
    }
    for (const row of recentShares) {
      velocityBySite.set(row.siteId, (velocityBySite.get(row.siteId) ?? 0) + row._count._all * 1.8);
    }
    const duplicateTitleCounts = new Map<string, number>();
    for (const row of sites) {
      const title = row.reports[0]?.title?.trim().toLowerCase();
      if (!title) continue;
      duplicateTitleCounts.set(title, (duplicateTitleCounts.get(title) ?? 0) + 1);
    }

    type SiteEnriched = Site & {
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

    const enrichedRows = await this.mapWithConcurrency(sites, 10, async (site) => {
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
          ? distanceInMeters(
              query.lat,
              query.lng,
              site.latitude,
              site.longitude,
            ) / 1000
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
        sessionGeoAffinity: distanceKm != null && query.radiusKm > 0 ? Math.max(0, 1 - distanceKm / query.radiusKm) : 0,
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
        id: siteBase.id,
        latitude: siteBase.latitude,
        longitude: siteBase.longitude,
        address: siteBase.address,
        description: siteBase.description,
        status: siteBase.status,
        upvotesCount: siteBase.upvotesCount,
        commentsCount: siteBase.commentsCount,
        sharesCount: siteBase.sharesCount,
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
        savesCount: siteBase.savesCount,
        isUpvotedByMe: Array.isArray(votes) && votes.length > 0,
        isSavedByMe: Array.isArray(saves) && saves.length > 0,
        rankingScore: rankingDetail.score,
        rankingReasons: rankingDetail.reasonCodes,
        ...(query.explain ? { rankingComponents: rankingDetail.components } : {}),
        distanceKm,
        createdAt: siteBase.createdAt,
        updatedAt: siteBase.updatedAt,
      } as SiteEnriched;
    });
    let enriched = enrichedRows;
    enriched = this.applyUserPreferences(enriched, user);

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
    enriched = this.applyDiversityRerank(enriched, query);
    if (cursorState?.hybrid != null) {
      enriched = enriched.filter((row) => this.isAfterRankedCursor(row, cursorState.hybrid!));
    }

    const total = query.cursor ? 0 : await this.prisma.site.count({ where });
    const skip = query.cursor ? 0 : (query.page - 1) * query.limit;
    const data = enriched.slice(skip, skip + query.limit);
    const nextCursor = data.length === query.limit
      ? rankedHybrid
        ? this.encodeHybridFeedCursor(
            data[data.length - 1].rankingScore,
            data[data.length - 1].id,
            data[data.length - 1].createdAt,
          )
        : this.encodeRankedFeedCursor(data[data.length - 1].rankingScore, data[data.length - 1].id)
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
    const response = {
      data: responseData as typeof data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        nextCursor,
      },
    };
    const duplicateCount = new Set(data.map((row) => row.id)).size !== data.length;
    if (duplicateCount) {
      ObservabilityStore.recordFeedPaginationContinuityIssue();
    }
    ObservabilityStore.recordFeedReasonCodes(
      data.flatMap((row) => row.rankingReasons ?? []),
    );
    this.feedResponseCache.set(cacheKey, { cachedAt: nowMs, value: response });
    this.indexCacheKeySites(
      cacheKey,
      data.map((row) => row.id),
    );
    if (this.feedResponseCache.size > 300) {
      const oldestKey = this.feedResponseCache.keys().next().value as string | undefined;
      if (oldestKey) this.removeCacheKey(oldestKey);
    }
    ObservabilityStore.recordFeedRequest({
      durationMs: Date.now() - startedAt,
      candidatePoolSize: enriched.length,
      cacheHit: false,
    });
    return response;
  }

  async findAllForMap(query: ListSitesMapQueryDto) {
    const startedAt = Date.now();
    this.validateMapViewportQuery(query);
    const cacheKey = this.buildMapCacheKey(query);
    const cached = this.mapResponseCache.get(cacheKey);
    const nowMs = Date.now();
    if (cached && nowMs - cached.cachedAt <= this.mapCacheTtlMs) {
      ObservabilityStore.recordMapRequest({
        durationMs: Date.now() - startedAt,
        candidatePoolSize: cached.value.data.length,
        cacheHit: true,
      });
      return cached.value;
    }

    const limit = Math.min(Math.max(query.limit, 10), 260);
    const mapTimeoutMs = Math.min(this.feedQueryTimeoutMs, 4_000);
    const isLite = query.detail === 'lite';
    let sites: MapSiteRow[] | MapSiteLiteRow[];
    let usedPostgisExactGeo = false;
    try {
      const postgisOk = await this.isPostgisMapAvailable();
      if (postgisOk) {
        try {
          sites = await this.withTimeout(
            this.loadMapSitesWithPostgis(query, limit),
            mapTimeoutMs,
            'Map query timed out',
          );
          usedPostgisExactGeo = true;
        } catch {
          sites = await this.withTimeout(
            this.loadMapSitesWithPrismaBounds(query, limit),
            mapTimeoutMs,
            'Map query timed out',
          );
        }
      } else {
        sites = await this.withTimeout(
          this.loadMapSitesWithPrismaBounds(query, limit),
          mapTimeoutMs,
          'Map query timed out',
        );
      }
    } catch (error) {
      if (cached) {
        ObservabilityStore.recordMapRequest({
          durationMs: Date.now() - startedAt,
          candidatePoolSize: cached.value.data.length,
          cacheHit: true,
        });
        return cached.value;
      }
      throw error;
    }

    const data: MapListApiRow[] = (isLite
      ? await this.mapWithConcurrency(sites as MapSiteLiteRow[], 8, async (site) => {
          const firstReport = site.reports[0];
          const signedMedia =
            firstReport != null && firstReport.mediaUrls.length > 0
              ? await this.reportsUploadService.signUrls(firstReport.mediaUrls.slice(0, 1))
              : undefined;
          const distanceKm = this.computeMapDistanceKm(query, site.latitude, site.longitude);
          return {
            id: site.id,
            latitude: site.latitude,
            longitude: site.longitude,
            address: site.address,
            description: site.description,
            status: site.status,
            upvotesCount: 0,
            commentsCount: 0,
            savesCount: 0,
            sharesCount: 0,
            reportCount: firstReport != null ? 1 : 0,
            latestReportTitle: null,
            latestReportDescription: null,
            latestReportCategory: null,
            latestReportCreatedAt: null,
            latestReportNumber: null,
            ...(signedMedia != null && signedMedia.length > 0
              ? { latestReportMediaUrls: signedMedia }
              : {}),
            ...(distanceKm != null ? { distanceKm } : {}),
            createdAt: site.createdAt,
            updatedAt: site.updatedAt,
          } satisfies MapListApiRow;
        })
      : await this.mapWithConcurrency(sites as MapSiteRow[], 8, async (site) => {
          const firstReport = site.reports[0];
          const signedMedia =
            firstReport != null && firstReport.mediaUrls.length > 0
              ? await this.reportsUploadService.signUrls(firstReport.mediaUrls.slice(0, 1))
              : undefined;
          const distanceKm = this.computeMapDistanceKm(query, site.latitude, site.longitude);
          return {
            id: site.id,
            latitude: site.latitude,
            longitude: site.longitude,
            address: site.address,
            description: site.description,
            status: site.status,
            upvotesCount: site.upvotesCount,
            commentsCount: site.commentsCount,
            savesCount: site.savesCount,
            sharesCount: site.sharesCount,
            reportCount: site._count.reports,
            latestReportTitle: firstReport?.title ?? null,
            latestReportDescription: firstReport?.description ?? null,
            latestReportCategory: firstReport?.category ?? null,
            latestReportCreatedAt: firstReport?.createdAt?.toISOString() ?? null,
            latestReportNumber: firstReport?.reportNumber ?? null,
            ...(signedMedia != null && signedMedia.length > 0
              ? { latestReportMediaUrls: signedMedia }
              : {}),
            ...(distanceKm != null ? { distanceKm } : {}),
            createdAt: site.createdAt,
            updatedAt: site.updatedAt,
          } satisfies MapListApiRow;
        })) as MapListApiRow[];

    // Client hint: presigned report media uses ~1h AWS expiry; refresh map before then.
    const signedMediaExpiresAt = new Date(
      Date.now() + SitesService.MAP_SIGNED_MEDIA_CLIENT_BUFFER_MS,
    ).toISOString();
    const response = {
      data: usedPostgisExactGeo ? data : this.filterMapRowsToExactRadius(data, query),
      meta: { signedMediaExpiresAt },
    };
    this.mapResponseCache.set(cacheKey, { cachedAt: nowMs, value: response });
    this.indexMapCacheKeySites(
      cacheKey,
      response.data.map((row) => row.id),
    );
    if (this.mapResponseCache.size > 300) {
      const oldestKey = this.mapResponseCache.keys().next().value as string | undefined;
      if (oldestKey) this.removeMapCacheKey(oldestKey);
    }
    ObservabilityStore.recordMapRequest({
      durationMs: Date.now() - startedAt,
      candidatePoolSize: response.data.length,
      cacheHit: false,
    });
    return response;
  }

  async findOne(
    siteId: string,
    user?: AuthenticatedUser,
  ): Promise<
    SiteWithReportsAndEvents & {
      upvotesCount: number;
      commentsCount: number;
      savesCount: number;
      sharesCount: number;
      isUpvotedByMe: boolean;
      isSavedByMe: boolean;
    }
  > {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      include: {
        reports: {
          orderBy: { createdAt: 'desc' },
          include: {
            reporter: {
              select: { firstName: true, lastName: true, avatarObjectKey: true },
            },
            coReporters: {
              include: {
                user: { select: { firstName: true, lastName: true } },
              },
            },
          },
        },
        events: {
          orderBy: { scheduledAt: 'asc' },
        },
      },
    });

    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    const reportsWithSignedUrls = await Promise.all(
      site.reports.map(async (r) => {
        const mediaUrls = await this.reportsUploadService.signUrls(r.mediaUrls);
        const reporter =
          r.reporter == null
            ? null
            : {
                firstName: r.reporter.firstName,
                lastName: r.reporter.lastName,
                avatarUrl: await this.reportsUploadService.signPrivateObjectKey(
                  r.reporter.avatarObjectKey,
                ),
              };
        const coReporters = r.coReporters.map((cr) => ({
          id: cr.id,
          createdAt: cr.createdAt,
          reportId: cr.reportId,
          userId: cr.userId,
          user: cr.user
            ? { firstName: cr.user.firstName, lastName: cr.user.lastName }
            : null,
        }));
        return {
          id: r.id,
          createdAt: r.createdAt,
          reportNumber: r.reportNumber,
          siteId: r.siteId,
          reporterId: r.reporterId,
          title: r.title,
          description: r.description,
          mediaUrls,
          category: r.category,
          severity: r.severity,
          cleanupEffort: r.cleanupEffort,
          status: r.status,
          moderatedAt: r.moderatedAt,
          moderationReason: r.moderationReason,
          moderatedById: r.moderatedById,
          potentialDuplicateOfId: r.potentialDuplicateOfId,
          reporter,
          coReporters,
        };
      }),
    );

    let isUpvotedByMe = false;
    let isSavedByMe = false;
    if (user) {
      const [vote, save] = await Promise.all([
        this.prisma.siteVote.findUnique({
          where: { siteId_userId: { siteId, userId: user.userId } },
          select: { id: true },
        }),
        this.prisma.siteSave.findUnique({
          where: { siteId_userId: { siteId, userId: user.userId } },
          select: { id: true },
        }),
      ]);
      isUpvotedByMe = Boolean(vote);
      isSavedByMe = Boolean(save);
    }

    return {
      ...site,
      reports: reportsWithSignedUrls,
      upvotesCount: site.upvotesCount,
      commentsCount: site.commentsCount,
      savesCount: site.savesCount,
      sharesCount: site.sharesCount,
      isUpvotedByMe,
      isSavedByMe,
    };
  }

  async findSiteMedia(siteId: string, query: ListSiteMediaQueryDto) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const reports = await this.prisma.report.findMany({
      where: { siteId },
      orderBy: { createdAt: 'desc' },
      select: { id: true, mediaUrls: true, createdAt: true },
    });
    const allItems = reports.flatMap((report) =>
      report.mediaUrls.map((url, index) => ({
        id: `${report.id}:${index}`,
        reportId: report.id,
        createdAt: report.createdAt.toISOString(),
        originalUrl: url,
      })),
    );

    const total = allItems.length;
    const skip = (query.page - 1) * query.limit;
    const pageItems = allItems.slice(skip, skip + query.limit);
    const signedUrls = await this.reportsUploadService.signUrls(
      pageItems.map((item) => item.originalUrl),
    );
    const data = pageItems.map((item, index) => ({
      id: item.id,
      reportId: item.reportId,
      createdAt: item.createdAt,
      url: signedUrls[index] ?? item.originalUrl,
    }));
    return {
      data,
      meta: { page: query.page, limit: query.limit, total },
    };
  }

  async findSiteComments(
    siteId: string,
    query: ListSiteCommentsQueryDto,
    user?: AuthenticatedUser,
  ): Promise<{ data: SiteCommentTreeNode[]; meta: { page: number; limit: number; total: number } }> {
    await this.siteEngagement.ensureSiteExists(siteId);
    const baseWhere = { siteId, isDeleted: false };
    const maxThreadDepth = 6;

    if (query.parentId) {
      const where = { ...baseWhere, parentId: query.parentId };
      const [total, comments] = await Promise.all([
        this.prisma.siteComment.count({ where }),
        this.prisma.siteComment.findMany({
          where,
          orderBy: { createdAt: 'desc' },
          skip: (query.page - 1) * query.limit,
          take: query.limit,
          include: {
            author: {
              select: { firstName: true, lastName: true },
            },
            likes: user
              ? {
                  where: { userId: user.userId },
                  select: { id: true },
                  take: 1,
                }
              : false,
          },
        }),
      ]);
      const ordered =
        query.sort === SiteCommentsSort.TOP
          ? [...comments].sort((a, b) => this.compareCommentsTop(a, b))
          : comments;
      return {
        data: ordered.map((comment) => ({
          id: comment.id,
          parentId: comment.parentId,
          body: comment.body,
          createdAt: comment.createdAt.toISOString(),
          authorId: comment.authorId,
          authorName: `${comment.author.firstName} ${comment.author.lastName}`.trim(),
          likesCount: comment.likesCount,
          isLikedByMe: Array.isArray(comment.likes) && comment.likes.length > 0,
          replies: [],
          repliesCount: 0,
        })),
        meta: { page: query.page, limit: query.limit, total },
      };
    }

    const rootsWhere = { ...baseWhere, parentId: null };
    const [total, rootComments] = await Promise.all([
      this.prisma.siteComment.count({ where: rootsWhere }),
      this.prisma.siteComment.findMany({
        where: rootsWhere,
        orderBy: { createdAt: 'desc' },
        skip: (query.page - 1) * query.limit,
        take: query.limit,
        include: {
          author: {
            select: { firstName: true, lastName: true },
          },
          likes: user
            ? {
                where: { userId: user.userId },
                select: { id: true },
                take: 1,
              }
            : false,
        },
      }),
    ]);

    const rootIds = rootComments.map((c) => c.id);
    const descendants: Array<
      Prisma.SiteCommentGetPayload<{
        include: { author: { select: { firstName: true; lastName: true } } };
      }>
    > = [];
    let frontier = [...rootIds];
    let depth = 0;
    while (frontier.length > 0 && depth < maxThreadDepth) {
      const children = await this.prisma.siteComment.findMany({
        where: {
          ...baseWhere,
          parentId: { in: frontier },
        },
        orderBy: { createdAt: 'asc' },
        include: {
          author: {
            select: { firstName: true, lastName: true },
          },
          likes: user
            ? {
                where: { userId: user.userId },
                select: { id: true },
                take: 1,
              }
            : false,
        },
      });
      if (children.length === 0) break;
      descendants.push(...children);
      frontier = children.map((c) => c.id);
      depth += 1;
    }

    const all = [...rootComments, ...descendants];
    const byParent = new Map<string, typeof all>();
    for (const comment of all) {
      if (!comment.parentId) continue;
      const list = byParent.get(comment.parentId) ?? [];
      list.push(comment);
      byParent.set(comment.parentId, list);
    }

    const mapNode = (comment: (typeof all)[number]): SiteCommentTreeNode => {
      const rawReplies = (byParent.get(comment.id) ?? []).map(mapNode);
      const replies =
        query.sort === SiteCommentsSort.TOP
          ? [...rawReplies].sort((a, b) => this.compareCommentNodesTop(a, b))
          : rawReplies.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
      return {
        id: comment.id,
        parentId: comment.parentId,
        body: comment.body,
        createdAt: comment.createdAt.toISOString(),
        authorId: comment.authorId,
        authorName: `${comment.author.firstName} ${comment.author.lastName}`.trim(),
        likesCount: comment.likesCount,
        isLikedByMe:
          Array.isArray((comment as { likes?: Array<{ id: string }> }).likes) &&
          ((comment as { likes?: Array<{ id: string }> }).likes?.length ?? 0) > 0,
        replies,
        repliesCount: replies.length,
      };
    };

    const roots =
      query.sort === SiteCommentsSort.TOP
        ? [...rootComments].sort((a, b) => this.compareCommentsTop(a, b))
        : rootComments;

    return {
      data: roots.map(mapNode),
      meta: { page: query.page, limit: query.limit, total },
    };
  }

  async createSiteComment(
    siteId: string,
    dto: CreateSiteCommentDto,
    user: AuthenticatedUser,
  ) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const body = dto.body.trim();
    if (!body) {
      throw new BadRequestException({
        code: 'COMMENT_EMPTY',
        message: 'Comment body cannot be empty.',
      });
    }
    if (dto.parentId) {
      const parent = await this.prisma.siteComment.findUnique({
        where: { id: dto.parentId },
        select: { id: true, siteId: true, isDeleted: true },
      });
      if (!parent || parent.isDeleted || parent.siteId !== siteId) {
        throw new BadRequestException({
          code: 'INVALID_PARENT_COMMENT',
          message: 'Parent comment is invalid for this site.',
        });
      }
    }
    const result = await this.prisma.$transaction(async (tx) => {
      const comment = await tx.siteComment.create({
        data: { siteId, authorId: user.userId, body, parentId: dto.parentId ?? null },
        include: { author: { select: { firstName: true, lastName: true } } },
      });
      await tx.site.update({
        where: { id: siteId },
        data: { commentsCount: { increment: 1 } },
      });
      return comment;
    });
    this.invalidateFeedCache('comment_created', siteId);
    this.emitSiteNotification(siteId, user.userId, 'COMMENT', 'New comment on a site you follow');
    return {
      id: result.id,
      parentId: result.parentId,
      body: result.body,
      createdAt: result.createdAt.toISOString(),
      authorId: result.authorId,
      authorName: `${result.author.firstName} ${result.author.lastName}`.trim(),
      likesCount: result.likesCount,
      isLikedByMe: false,
      replies: [],
      repliesCount: 0,
    };
  }

  async likeSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const comment = await this.prisma.siteComment.findUnique({
      where: { id: commentId },
      select: { id: true, siteId: true, isDeleted: true, likesCount: true },
    });
    if (!comment || comment.isDeleted || comment.siteId !== siteId) {
      throw new NotFoundException({
        code: 'COMMENT_NOT_FOUND',
        message: 'Comment not found for this site.',
      });
    }
    const result = await this.prisma.$transaction(async (tx) => {
      const existing = await tx.siteCommentLike.findUnique({
        where: { commentId_userId: { commentId, userId: user.userId } },
        select: { id: true },
      });
      if (!existing) {
        await tx.siteCommentLike.create({
          data: { commentId, userId: user.userId },
        });
        return tx.siteComment.update({
          where: { id: commentId },
          data: { likesCount: { increment: 1 } },
          select: { id: true, likesCount: true },
        });
      }
      return tx.siteComment.findUniqueOrThrow({
        where: { id: commentId },
        select: { id: true, likesCount: true },
      });
    });
    this.invalidateFeedCache('comment_liked', siteId);
    return { commentId: result.id, likesCount: result.likesCount, isLikedByMe: true };
  }

  async unlikeSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const comment = await this.prisma.siteComment.findUnique({
      where: { id: commentId },
      select: { id: true, siteId: true, isDeleted: true, likesCount: true },
    });
    if (!comment || comment.isDeleted || comment.siteId !== siteId) {
      throw new NotFoundException({
        code: 'COMMENT_NOT_FOUND',
        message: 'Comment not found for this site.',
      });
    }
    const result = await this.prisma.$transaction(async (tx) => {
      const deleted = await tx.siteCommentLike.deleteMany({
        where: { commentId, userId: user.userId },
      });
      if (deleted.count > 0) {
        return tx.siteComment.update({
          where: { id: commentId },
          data: { likesCount: { decrement: 1 } },
          select: { id: true, likesCount: true },
        });
      }
      return tx.siteComment.findUniqueOrThrow({
        where: { id: commentId },
        select: { id: true, likesCount: true },
      });
    });
    this.invalidateFeedCache('comment_unliked', siteId);
    return { commentId: result.id, likesCount: Math.max(0, result.likesCount), isLikedByMe: false };
  }

  async updateSiteComment(
    siteId: string,
    commentId: string,
    dto: UpdateSiteCommentDto,
    user: AuthenticatedUser,
  ) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const body = dto.body.trim();
    if (!body) {
      throw new BadRequestException({
        code: 'COMMENT_EMPTY',
        message: 'Comment body cannot be empty.',
      });
    }
    const comment = await this.prisma.siteComment.findUnique({
      where: { id: commentId },
      select: {
        id: true,
        siteId: true,
        authorId: true,
        isDeleted: true,
        parentId: true,
        createdAt: true,
        likesCount: true,
        author: { select: { firstName: true, lastName: true } },
      },
    });
    if (!comment || comment.isDeleted || comment.siteId !== siteId) {
      throw new NotFoundException({
        code: 'COMMENT_NOT_FOUND',
        message: 'Comment not found for this site.',
      });
    }
    if (comment.authorId !== user.userId) {
      throw new ForbiddenException({
        code: 'COMMENT_FORBIDDEN',
        message: 'You can edit only your own comments.',
      });
    }
    const updated = await this.prisma.siteComment.update({
      where: { id: commentId },
      data: { body },
      include: { author: { select: { firstName: true, lastName: true } } },
    });
    this.invalidateFeedCache('comment_updated', siteId);
    return {
      id: updated.id,
      parentId: updated.parentId,
      body: updated.body,
      createdAt: updated.createdAt.toISOString(),
      authorId: updated.authorId,
      authorName: `${updated.author.firstName} ${updated.author.lastName}`.trim(),
      likesCount: updated.likesCount,
      isLikedByMe: false,
      replies: [],
      repliesCount: 0,
    };
  }

  async deleteSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const comment = await this.prisma.siteComment.findUnique({
      where: { id: commentId },
      select: { id: true, siteId: true, authorId: true, isDeleted: true },
    });
    if (!comment || comment.isDeleted || comment.siteId !== siteId) {
      throw new NotFoundException({
        code: 'COMMENT_NOT_FOUND',
        message: 'Comment not found for this site.',
      });
    }
    if (comment.authorId !== user.userId) {
      throw new ForbiddenException({
        code: 'COMMENT_FORBIDDEN',
        message: 'You can delete only your own comments.',
      });
    }
    const affectedCount = await this.prisma.$transaction(async (tx) => {
      const descendants = await tx.siteComment.findMany({
        where: { siteId, isDeleted: false },
        select: { id: true, parentId: true },
      });
      const byParent = new Map<string, string[]>();
      for (const row of descendants) {
        if (!row.parentId) continue;
        const list = byParent.get(row.parentId) ?? [];
        list.push(row.id);
        byParent.set(row.parentId, list);
      }
      const toDelete = new Set<string>();
      const stack: string[] = [commentId];
      while (stack.length > 0) {
        const current = stack.pop();
        if (!current || toDelete.has(current)) continue;
        toDelete.add(current);
        const children = byParent.get(current) ?? [];
        stack.push(...children);
      }
      const ids = [...toDelete];
      await tx.siteCommentLike.deleteMany({
        where: { commentId: { in: ids } },
      });
      const updated = await tx.siteComment.updateMany({
        where: { id: { in: ids }, isDeleted: false },
        data: { isDeleted: true },
      });
      if (updated.count > 0) {
        await tx.site.update({
          where: { id: siteId },
          data: { commentsCount: { decrement: updated.count } },
        });
      }
      return updated.count;
    });
    this.invalidateFeedCache('comment_deleted', siteId);
    return { commentId, deletedCount: affectedCount };
  }

  async upvoteSite(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.upvote(siteId, user.userId);
    this.invalidateFeedCache('site_upvoted', siteId);
    this.emitSiteNotification(siteId, user.userId, 'UPVOTE', 'Your report received an upvote');
    return this.getEngagementSnapshot(siteId, user.userId);
  }

  async removeSiteUpvote(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.removeUpvote(siteId, user.userId);
    this.invalidateFeedCache('site_upvote_removed', siteId);
    return this.getEngagementSnapshot(siteId, user.userId);
  }

  async saveSite(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.save(siteId, user.userId);
    this.invalidateFeedCache('site_saved', siteId);
    return this.getEngagementSnapshot(siteId, user.userId);
  }

  async unsaveSite(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.unsave(siteId, user.userId);
    this.invalidateFeedCache('site_unsaved', siteId);
    return this.getEngagementSnapshot(siteId, user.userId);
  }

  async shareSite(siteId: string, dto: ShareSiteDto, user: AuthenticatedUser) {
    await this.siteEngagement.share(siteId, user.userId, dto.channel ?? SiteShareChannel.native);
    this.invalidateFeedCache('site_shared', siteId);
    return this.getEngagementSnapshot(siteId, user.userId);
  }

  async trackFeedEvent(dto: TrackFeedEventDto, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(dto.siteId);
    const metadata = {
      sessionId: dto.sessionId ?? null,
      ...(dto.metadata ? { metadata: dto.metadata } : {}),
    } as Prisma.InputJsonValue;
    void this.audit.log({
      actorId: user.userId,
      action: `FEED_EVENT_${dto.eventType.toUpperCase()}`,
      resourceType: 'Feed',
      resourceId: dto.siteId,
      metadata,
    });
    if (dto.eventType === 'impression') {
      const prefs = this.feedUserPreferences.get(user.userId) ?? {
        hiddenSiteIds: new Set<string>(),
        mutedCategories: new Map<string, number>(),
        seenSiteIds: new Map<string, number>(),
        updatedAt: Date.now(),
      };
      prefs.seenSiteIds.set(dto.siteId, Date.now());
      if (prefs.seenSiteIds.size > 300) {
        const oldest = [...prefs.seenSiteIds.entries()].sort((a, b) => a[1] - b[1]).slice(0, 80);
        for (const [siteId] of oldest) {
          prefs.seenSiteIds.delete(siteId);
        }
      }
      prefs.updatedAt = Date.now();
      this.feedUserPreferences.set(user.userId, prefs);
    }
    return { ok: true };
  }

  async submitFeedFeedback(siteId: string, dto: SubmitFeedFeedbackDto, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const metadata = {
      sessionId: dto.sessionId ?? null,
      ...(dto.metadata ? { metadata: dto.metadata } : {}),
    } as Prisma.InputJsonValue;
    void this.audit.log({
      actorId: user.userId,
      action: `FEED_FEEDBACK_${dto.feedbackType.toUpperCase()}`,
      resourceType: 'Site',
      resourceId: siteId,
      metadata,
    });
    this.applyFeedFeedbackPreference(user.userId, siteId, dto.feedbackType);
    ObservabilityStore.recordFeedFeedback(dto.feedbackType);
    this.invalidateFeedCache('feed_feedback', siteId);
    return { ok: true, siteId, feedbackType: dto.feedbackType };
  }

  private async getEngagementSnapshot(siteId: string, userId: string) {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      include: {
        votes: {
          where: { userId },
          select: { id: true },
          take: 1,
        },
        saves: {
          where: { userId },
          select: { id: true },
          take: 1,
        },
      },
    });
    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }
    return {
      siteId,
      upvotesCount: site.upvotesCount,
      commentsCount: site.commentsCount,
      savesCount: site.savesCount,
      sharesCount: site.sharesCount,
      isUpvotedByMe: site.votes.length > 0,
      isSavedByMe: site.saves.length > 0,
    };
  }

  async updateStatus(
    siteId: string,
    dto: UpdateSiteStatusDto,
    admin: AuthenticatedUser,
  ): Promise<Site> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      select: { id: true, status: true },
    });

    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    if (site.status === dto.status) {
      return this.prisma.site.findUniqueOrThrow({
        where: { id: siteId },
      });
    }

    const allowedStatuses = ALLOWED_SITE_STATUS_TRANSITIONS[site.status];
    if (!allowedStatuses.includes(dto.status)) {
      throw new BadRequestException({
        code: 'INVALID_SITE_STATUS_TRANSITION',
        message: `Cannot transition site status from '${site.status}' to '${dto.status}'`,
        details: {
          from: site.status,
          to: dto.status,
          allowedTo: allowedStatuses,
        },
      });
    }

    const updated = await this.prisma.site.update({
      where: { id: siteId },
      data: { status: dto.status },
    });

    this.siteEventsService.emitSiteUpdated(siteId, {
      kind: 'status_changed',
      status: updated.status,
      latitude: updated.latitude,
      longitude: updated.longitude,
      updatedAt: updated.updatedAt,
    });

    await this.audit.log({
      actorId: admin.userId,
      action: 'SITE_STATUS_UPDATED',
      resourceType: 'Site',
      resourceId: siteId,
      metadata: { from: site.status, to: dto.status },
    });

    this.invalidateFeedCache('site_status_updated');
    this.invalidateMapCache('site_status_updated', updated.id);
    return updated;
  }

  async assertSiteEligibleForEcoAction(siteId: string): Promise<void> {
    const approvedCount = await this.prisma.report.count({
      where: {
        siteId,
        status: ReportStatus.APPROVED,
      },
    });
    if (approvedCount === 0) {
      throw new BadRequestException({
        code: 'SITE_NOT_APPROVED_FOR_ECO_ACTIONS',
        message: 'Site must have at least one approved report to create eco actions.',
      });
    }
  }

  private compareCommentsTop(
    a: { likesCount: number; createdAt: Date; id: string },
    b: { likesCount: number; createdAt: Date; id: string },
  ): number {
    const scoreB = this.computeCommentTopScore(b.likesCount, b.createdAt, b.id);
    const scoreA = this.computeCommentTopScore(a.likesCount, a.createdAt, a.id);
    return scoreB - scoreA;
  }

  private compareCommentNodesTop(a: SiteCommentTreeNode, b: SiteCommentTreeNode): number {
    const scoreB = this.computeCommentTopScore(
      b.likesCount + b.repliesCount,
      new Date(b.createdAt),
      b.id,
    );
    const scoreA = this.computeCommentTopScore(
      a.likesCount + a.repliesCount,
      new Date(a.createdAt),
      a.id,
    );
    return scoreB - scoreA;
  }

  private computeCommentTopScore(baseSignals: number, createdAt: Date, id: string): number {
    const ageHours = Math.max(0, (Date.now() - createdAt.getTime()) / (1000 * 60 * 60));
    const freshness = Math.exp(-Math.log(2) * (ageHours / 24));
    const engagement = Math.log1p(Math.max(0, baseSignals));
    const jitter = this.commentJitter(id);
    return freshness * 0.55 + engagement * 0.45 + jitter;
  }

  private commentJitter(id: string): number {
    let hash = 0;
    for (let i = 0; i < id.length; i++) {
      hash = (hash * 31 + id.charCodeAt(i)) | 0;
    }
    return ((Math.abs(hash) % 1000) / 1000 - 0.5) * 0.01;
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

  private applyDiversityRerank<
    T extends {
      id: string;
      latestReportCategory: string | null;
      latestReportReporterId?: string | null;
      rankingScore: number;
    },
  >(
    rows: T[],
    query: ListSitesQueryDto,
  ): T[] {
    if (query.sort !== SiteFeedSort.HYBRID || query.mode === SiteFeedMode.LATEST || rows.length < 4) {
      return rows;
    }
    const output: T[] = [];
    const remaining = [...rows];
    while (remaining.length > 0) {
      if (output.length < 2) {
        output.push(remaining.shift() as T);
        continue;
      }
      const prevCategory = output[output.length - 1].latestReportCategory;
      const prevAuthor = output[output.length - 1].latestReportReporterId ?? null;
      const candidateIndex = remaining.findIndex(
        (item) =>
          item.latestReportCategory !== prevCategory &&
          (item.latestReportReporterId ?? null) !== prevAuthor,
      );
      if (candidateIndex >= 0 && candidateIndex <= 3) {
        output.push(...remaining.splice(candidateIndex, 1));
      } else {
        output.push(remaining.shift() as T);
      }
    }
    return output;
  }

  private encodeRankedFeedCursor(rankingScore: number, id: string): string {
    return `r|${rankingScore.toFixed(8)}|${id}`;
  }

  private encodeHybridFeedCursor(rankingScore: number, id: string, createdAt: Date): string {
    return `h|${rankingScore.toFixed(8)}|${id}|${createdAt.getTime()}`;
  }

  private decodeFeedCursor(
    cursor: string | undefined,
    hybridRanked: boolean,
  ): { dbClause: Prisma.SiteWhereInput | null; hybrid?: { score: number; id: string } } | null {
    if (!cursor) return null;
    const [kind, first, second] = cursor.split('|');
    if (kind === 'r') {
      const score = Number(first);
      const id = second;
      if (!Number.isFinite(score) || !id) return { dbClause: null };
      return { dbClause: null, hybrid: { score, id } };
    }
    if (kind === 'h') {
      const score = Number(first);
      const id = second;
      if (!hybridRanked || !Number.isFinite(score) || !id) return { dbClause: null };
      return { dbClause: null, hybrid: { score, id } };
    }
    const timestampRaw = kind === 'c' ? first : kind;
    const id = kind === 'c' ? second : first;
    const timestamp = Number(timestampRaw);
    if (!Number.isFinite(timestamp) || !id) return { dbClause: null };
    const createdAt = new Date(timestamp);
    if (Number.isNaN(createdAt.getTime())) return { dbClause: null };
    return {
      dbClause: {
        OR: [
          { createdAt: { lt: createdAt } },
          {
            AND: [{ createdAt }, { id: { lt: id } }],
          },
        ],
      },
    };
  }

  private hasMapViewportBounds(query: ListSitesMapQueryDto): boolean {
    return (
      query.minLat != null &&
      query.maxLat != null &&
      query.minLng != null &&
      query.maxLng != null
    );
  }

  private validateMapViewportQuery(query: ListSitesMapQueryDto): void {
    const hasAnyBounds =
      query.minLat != null ||
      query.maxLat != null ||
      query.minLng != null ||
      query.maxLng != null;
    const hasAllBounds = this.hasMapViewportBounds(query);
    if (hasAnyBounds && !hasAllBounds) {
      throw new BadRequestException({
        code: 'INVALID_MAP_VIEWPORT',
        message: 'All map viewport bounds must be provided together.',
      });
    }
    if (hasAllBounds && (query.minLat! > query.maxLat! || query.minLng! > query.maxLng!)) {
      throw new BadRequestException({
        code: 'INVALID_MAP_VIEWPORT',
        message: 'Map viewport bounds are invalid.',
      });
    }
  }

  private buildMapWhere(query: ListSitesMapQueryDto): Prisma.SiteWhereInput {
    const where: Prisma.SiteWhereInput = query.status ? { status: query.status } : {};
    if (this.hasMapViewportBounds(query)) {
      where.latitude = {
        gte: query.minLat!,
        lte: query.maxLat!,
      };
      where.longitude = {
        gte: query.minLng!,
        lte: query.maxLng!,
      };
      return where;
    }

    const radiusMeters = (query.radiusKm ?? 10) * 1000;
    const metersPerDegreeLat = 111_320;
    const deltaLat = radiusMeters / metersPerDegreeLat;
    const metersPerDegreeLng =
      Math.cos((query.lat * Math.PI) / 180) * metersPerDegreeLat || metersPerDegreeLat;
    const deltaLng = radiusMeters / metersPerDegreeLng;
    where.latitude = {
      gte: query.lat - deltaLat,
      lte: query.lat + deltaLat,
    };
    where.longitude = {
      gte: query.lng - deltaLng,
      lte: query.lng + deltaLng,
    };
    return where;
  }

  private async isPostgisMapAvailable(): Promise<boolean> {
    if (this.postgisMapSupport !== null) {
      return this.postgisMapSupport;
    }
    try {
      const rows = await this.prisma.$queryRaw<{ ok: number }[]>`
        SELECT 1::int as ok FROM pg_extension WHERE extname = 'postgis' LIMIT 1
      `;
      this.postgisMapSupport = rows.length > 0;
    } catch {
      this.postgisMapSupport = false;
    }
    return this.postgisMapSupport;
  }

  private async queryMapSiteIdsByPostgis(query: ListSitesMapQueryDto, limit: number): Promise<string[]> {
    const statusFragment = query.status
      ? Prisma.sql`AND s.status = ${query.status}::"SiteStatus"`
      : Prisma.empty;

    if (this.hasMapViewportBounds(query)) {
      const rows = await this.prisma.$queryRaw<{ id: string }[]>`
        SELECT s.id FROM "Site" s
        WHERE s.latitude IS NOT NULL AND s.longitude IS NOT NULL
          AND ST_Within(
            ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326),
            ST_MakeEnvelope(${query.minLng}, ${query.minLat}, ${query.maxLng}, ${query.maxLat}, 4326)
          )
          ${statusFragment}
        ORDER BY ST_Distance(
          ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${query.lng}, ${query.lat}), 4326)::geography
        ) ASC NULLS LAST,
        s.id ASC
        LIMIT ${limit}
      `;
      return rows.map((r) => r.id);
    }

    const radiusMeters = (query.radiusKm ?? 10) * 1000;
    const rows = await this.prisma.$queryRaw<{ id: string }[]>`
      SELECT s.id FROM "Site" s
      WHERE s.latitude IS NOT NULL AND s.longitude IS NOT NULL
        AND ST_DWithin(
          ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${query.lng}, ${query.lat}), 4326)::geography,
          ${radiusMeters}
        )
        ${statusFragment}
      ORDER BY ST_Distance(
        ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326)::geography,
        ST_SetSRID(ST_MakePoint(${query.lng}, ${query.lat}), 4326)::geography
      ) ASC NULLS LAST,
      s.id ASC
      LIMIT ${limit}
    `;
    return rows.map((r) => r.id);
  }

  private mapSiteSelectForQuery(query: ListSitesMapQueryDto) {
    return query.detail === 'lite' ? MAP_SITE_LITE_SELECT : MAP_SITE_FIND_SELECT;
  }

  private async loadMapSitesWithPostgis(
    query: ListSitesMapQueryDto,
    limit: number,
  ): Promise<MapSiteRow[] | MapSiteLiteRow[]> {
    const ids = await this.queryMapSiteIdsByPostgis(query, limit);
    if (ids.length === 0) {
      return [];
    }
    const select = this.mapSiteSelectForQuery(query);
    const unsorted = await this.prisma.site.findMany({
      where: { id: { in: ids } },
      select,
    });
    const rank = new Map(ids.map((id, i) => [id, i]));
    return [...unsorted].sort((a, b) => (rank.get(a.id) ?? 0) - (rank.get(b.id) ?? 0)) as
      | MapSiteRow[]
      | MapSiteLiteRow[];
  }

  private async loadMapSitesWithPrismaBounds(
    query: ListSitesMapQueryDto,
    limit: number,
  ): Promise<MapSiteRow[] | MapSiteLiteRow[]> {
    const where = this.buildMapWhere(query);
    const select = this.mapSiteSelectForQuery(query);
    const rows = await this.prisma.site.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit,
      select,
    });
    return rows as MapSiteRow[] | MapSiteLiteRow[];
  }

  private computeMapDistanceKm(
    query: ListSitesMapQueryDto,
    latitude: number | null,
    longitude: number | null,
  ): number | undefined {
    if (latitude == null || longitude == null) {
      return undefined;
    }
    return distanceInMeters(query.lat, query.lng, latitude, longitude) / 1000;
  }

  private filterMapRowsToExactRadius<
    T extends { id: string; latitude: number | null; longitude: number | null; distanceKm?: number },
  >(rows: T[], query: ListSitesMapQueryDto): T[] {
    const radiusMeters = (query.radiusKm ?? 10) * 1000;
    return rows.filter((row) => {
      if (this.hasMapViewportBounds(query)) {
        return (
          row.latitude != null &&
          row.longitude != null &&
          row.latitude >= query.minLat! &&
          row.latitude <= query.maxLat! &&
          row.longitude >= query.minLng! &&
          row.longitude <= query.maxLng!
        );
      }
      if (row.distanceKm == null) {
        return false;
      }
      return row.distanceKm * 1000 <= radiusMeters;
    });
  }

  private buildMapCacheKey(query: ListSitesMapQueryDto): string {
    return [
      query.detail ?? 'full',
      query.status ?? '',
      query.limit,
      query.radiusKm.toFixed(1),
      query.lat.toFixed(4),
      query.lng.toFixed(4),
      query.minLat?.toFixed(4) ?? '',
      query.maxLat?.toFixed(4) ?? '',
      query.minLng?.toFixed(4) ?? '',
      query.maxLng?.toFixed(4) ?? '',
    ].join('|');
  }

  private buildFeedCacheKey(query: ListSitesQueryDto, user?: AuthenticatedUser): string {
    return [
      user?.userId ?? 'anon',
      query.page,
      query.limit,
      query.sort,
      query.mode,
      query.status ?? '',
      query.lat?.toFixed(4) ?? '',
      query.lng?.toFixed(4) ?? '',
      query.radiusKm,
      query.cursor ?? '',
      query.explain ? 1 : 0,
    ].join('|');
  }

  private isAfterRankedCursor(
    row: { rankingScore: number; id: string },
    cursor: { score: number; id: string },
  ): boolean {
    if (row.rankingScore < cursor.score) return true;
    if (row.rankingScore > cursor.score) return false;
    return row.id.localeCompare(cursor.id) < 0;
  }

  private indexCacheKeySites(cacheKey: string, siteIds: string[]): void {
    for (const siteId of siteIds) {
      const set = this.feedCacheSiteIndex.get(siteId) ?? new Set<string>();
      set.add(cacheKey);
      this.feedCacheSiteIndex.set(siteId, set);
    }
  }

  private removeCacheKey(cacheKey: string): void {
    const cached = this.feedResponseCache.get(cacheKey);
    if (cached) {
      for (const row of cached.value.data) {
        const keys = this.feedCacheSiteIndex.get(row.id);
        if (!keys) continue;
        keys.delete(cacheKey);
        if (keys.size === 0) this.feedCacheSiteIndex.delete(row.id);
      }
    }
    this.feedResponseCache.delete(cacheKey);
  }

  private indexMapCacheKeySites(cacheKey: string, siteIds: string[]): void {
    for (const siteId of siteIds) {
      const set = this.mapCacheSiteIndex.get(siteId) ?? new Set<string>();
      set.add(cacheKey);
      this.mapCacheSiteIndex.set(siteId, set);
    }
  }

  private removeMapCacheKey(cacheKey: string): void {
    const cached = this.mapResponseCache.get(cacheKey);
    if (cached) {
      for (const row of cached.value.data) {
        const keys = this.mapCacheSiteIndex.get(row.id);
        if (!keys) continue;
        keys.delete(cacheKey);
        if (keys.size === 0) this.mapCacheSiteIndex.delete(row.id);
      }
    }
    this.mapResponseCache.delete(cacheKey);
  }

  private invalidateFeedCache(reason: string, siteId?: string): void {
    ObservabilityStore.recordFeedCacheInvalidation(reason);
    if (siteId) {
      const keys = this.feedCacheSiteIndex.get(siteId);
      if (keys && keys.size > 0) {
        for (const key of [...keys]) {
          this.removeCacheKey(key);
        }
        this.feedCacheSiteIndex.delete(siteId);
        return;
      }
    }
    this.feedResponseCache.clear();
    this.feedCacheSiteIndex.clear();
  }

  private invalidateMapCache(reason: string, siteId?: string): void {
    ObservabilityStore.recordFeedCacheInvalidation(`map_${reason}`);
    if (siteId) {
      const keys = this.mapCacheSiteIndex.get(siteId);
      if (keys && keys.size > 0) {
        for (const key of [...keys]) {
          this.removeMapCacheKey(key);
        }
        this.mapCacheSiteIndex.delete(siteId);
        return;
      }
    }
    this.mapResponseCache.clear();
    this.mapCacheSiteIndex.clear();
  }

  private async withTimeout<T>(promise: Promise<T>, timeoutMs: number, message: string): Promise<T> {
    let timer: NodeJS.Timeout | null = null;
    try {
      return await Promise.race<T>([
        promise,
        new Promise<T>((_, reject) => {
          timer = setTimeout(() => reject(new Error(message)), timeoutMs);
        }),
      ]);
    } finally {
      if (timer) clearTimeout(timer);
    }
  }

  private async mapWithConcurrency<T, R>(
    input: T[],
    concurrency: number,
    mapper: (item: T) => Promise<R>,
  ): Promise<R[]> {
    const results = new Array<R>(input.length);
    let cursor = 0;
    const workers = Array.from({ length: Math.max(1, concurrency) }, async () => {
      while (true) {
        const index = cursor++;
        if (index >= input.length) break;
        results[index] = await mapper(input[index]);
      }
    });
    await Promise.all(workers);
    return results;
  }

  private applyFeedFeedbackPreference(
    userId: string,
    siteId: string,
    feedbackType: SubmitFeedFeedbackDto['feedbackType'],
  ): void {
    const prefs = this.feedUserPreferences.get(userId) ?? {
      hiddenSiteIds: new Set<string>(),
      mutedCategories: new Map<string, number>(),
      seenSiteIds: new Map<string, number>(),
      updatedAt: Date.now(),
    };
    if (feedbackType === 'not_relevant') {
      prefs.hiddenSiteIds.add(siteId);
    }
    prefs.updatedAt = Date.now();
    this.feedUserPreferences.set(userId, prefs);
  }

  private applyUserPreferences<
    T extends { id: string; latestReportCategory: string | null; rankingScore: number },
  >(rows: T[], user?: AuthenticatedUser): T[] {
    if (!user) return rows;
    const prefs = this.feedUserPreferences.get(user.userId);
    if (!prefs) return rows;
    if (Date.now() - prefs.updatedAt > 7 * 24 * 60 * 60 * 1000) {
      this.feedUserPreferences.delete(user.userId);
      return rows;
    }
    const filtered = rows.filter((row) => !prefs.hiddenSiteIds.has(row.id));
    const now = Date.now();
    return filtered.map((row) => {
      const key = row.latestReportCategory?.toUpperCase() ?? '';
      let penalty = prefs.mutedCategories.get(key) ?? 0;
      const seenAt = prefs.seenSiteIds.get(row.id);
      if (seenAt != null && now - seenAt < 24 * 60 * 60 * 1000) {
        penalty += 0.05;
      }
      if (penalty <= 0) return row;
      return {
        ...row,
        rankingScore: Math.max(0, row.rankingScore - penalty),
      };
    });
  }

  private emitSiteNotification(
    siteId: string,
    actorUserId: string,
    type: 'UPVOTE' | 'COMMENT' | 'SITE_UPDATE',
    body: string,
  ): void {
    this.prisma.site
      .findUnique({
        where: { id: siteId },
        select: {
          id: true,
          reports: {
            select: { reporterId: true },
            where: { reporterId: { not: null } },
            take: 50,
          },
        },
      })
      .then((site) => {
        if (!site) return;
        const recipientIds = [
          ...new Set(
            site.reports
              .map((r) => r.reporterId)
              .filter((id): id is string => id != null && id !== actorUserId),
          ),
        ];
        if (recipientIds.length === 0) return;
        this.eventEmitter.emit('notification.send', {
          recipientUserIds: recipientIds,
          title: type === 'UPVOTE' ? 'New upvote' : type === 'COMMENT' ? 'New comment' : 'Site update',
          body,
          type,
          threadKey: `site:${siteId}`,
          groupKey: `${type}:site:${siteId}`,
          data: { siteId, targetTab: '0' },
        });
      })
      .catch(() => {});
  }
}
