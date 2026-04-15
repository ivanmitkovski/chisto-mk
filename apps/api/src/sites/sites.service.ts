import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
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
import { ListSiteMediaQueryDto } from './dto/list-site-media-query.dto';
import { ListSiteUpvotesQueryDto } from './dto/list-site-upvotes-query.dto';
import { ListSitesQueryDto, SiteFeedMode, SiteFeedSort } from './dto/list-sites-query.dto';
import { CreateSiteCommentDto } from './dto/create-site-comment.dto';
import { UpdateSiteCommentDto } from './dto/update-site-comment.dto';
import { ShareSiteDto } from './dto/share-site.dto';
import { SubmitFeedFeedbackDto } from './dto/submit-feed-feedback.dto';
import { TrackFeedEventDto } from './dto/track-feed-event.dto';
import { UpdateSiteStatusDto } from './dto/update-site-status.dto';
import { FeedRankingService, RankingInput } from './feed-ranking.service';
import { SiteEngagementService } from './site-engagement.service';
import { SiteCommentsService } from './site-comments.service';
import type { SiteCommentTreeNode } from './site-comments.service';
import { SitesMapQueryService } from './sites-map-query.service';

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

  private readonly feedCacheTtlMs = 15_000;
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
    private readonly siteComments: SiteCommentsService,
    private readonly eventEmitter: EventEmitter2,
    private readonly sitesMapQuery: SitesMapQueryService,
  ) {}

  async findAllForMap(query: ListSitesMapQueryDto) {
    return this.sitesMapQuery.findAllForMap(query);
  }

  async create(dto: CreateSiteDto): Promise<Site> {
    const site = await this.prisma.site.create({
      data: {
        latitude: dto.latitude,
        longitude: dto.longitude,
        description: dto.description ?? null,
      },
    });
    this.invalidateFeedCache('site_created');
    this.sitesMapQuery.invalidateMapCache('site_created');
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


  /**
   * Stable list for mobile/site detail (deduped by userId, earliest reportedAt wins ordering).
   * [avatarUrl] is a signed URL when the user has an avatar object key.
   */
  private buildSiteCoReporterSummaries(
    reports: Array<{
      coReporters: Array<{
        userId: string;
        reportedAt: Date;
        user: { firstName: string; lastName: string; avatarUrl: string | null } | null;
      }>;
    }>,
  ): { userId: string; name: string; avatarUrl: string | null }[] {
    const anonymous = 'Anonymous';
    const pickRicher = (a: string, b: string): string => {
      if (a === anonymous && b !== anonymous) return b;
      if (b === anonymous && a !== anonymous) return a;
      return a;
    };
    const pickAvatar = (a: string | null, b: string | null): string | null => {
      const x = a?.trim() ?? '';
      const y = b?.trim() ?? '';
      if (x.length > 0) return x;
      if (y.length > 0) return y;
      return null;
    };
    const display = (user: { firstName: string; lastName: string; avatarUrl: string | null } | null): string => {
      if (!user) return anonymous;
      const n = `${user.firstName} ${user.lastName}`.trim();
      return n.length > 0 ? n : anonymous;
    };
    const byUser = new Map<
      string,
      { name: string; reportedAt: Date; avatarUrl: string | null }
    >();
    for (const r of reports) {
      for (const cr of r.coReporters) {
        const name = display(cr.user);
        const reportedAt = cr.reportedAt;
        const avatarUrl = cr.user?.avatarUrl?.trim() ? cr.user.avatarUrl : null;
        const prev = byUser.get(cr.userId);
        if (!prev) {
          byUser.set(cr.userId, { name, reportedAt, avatarUrl });
          continue;
        }
        const incomingEarlier = reportedAt < prev.reportedAt;
        const nextAt = incomingEarlier ? reportedAt : prev.reportedAt;
        const nextName = incomingEarlier ? pickRicher(name, prev.name) : pickRicher(prev.name, name);
        const nextAvatar = incomingEarlier
          ? pickAvatar(avatarUrl, prev.avatarUrl)
          : pickAvatar(prev.avatarUrl, avatarUrl);
        byUser.set(cr.userId, { name: nextName, reportedAt: nextAt, avatarUrl: nextAvatar });
      }
    }
    return [...byUser.entries()]
      .sort(([, av], [, bv]) => {
        if (av.reportedAt < bv.reportedAt) return -1;
        if (av.reportedAt > bv.reportedAt) return 1;
        return av.name.localeCompare(bv.name);
      })
      .map(([userId, v]) => ({ userId, name: v.name, avatarUrl: v.avatarUrl }));
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
      coReporterNames: string[];
      coReporterSummaries: { userId: string; name: string; avatarUrl: string | null }[];
      mergedDuplicateChildCountTotal: number;
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
                user: { select: { firstName: true, lastName: true, avatarObjectKey: true } },
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
        const coReporters = await Promise.all(
          r.coReporters.map(async (cr) => ({
            id: cr.id,
            createdAt: cr.createdAt,
            reportedAt: cr.reportedAt,
            reportId: cr.reportId,
            userId: cr.userId,
            user: cr.user
              ? {
                  firstName: cr.user.firstName,
                  lastName: cr.user.lastName,
                  avatarUrl: await this.reportsUploadService.signPrivateObjectKey(cr.user.avatarObjectKey),
                }
              : null,
          })),
        );
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
          mergedDuplicateChildCount: r.mergedDuplicateChildCount,
        };
      }),
    );

    const mergedDuplicateChildCountTotal = reportsWithSignedUrls.reduce(
      (n, r) => n + (r.mergedDuplicateChildCount ?? 0),
      0,
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

    const coReporterSummaries = this.buildSiteCoReporterSummaries(reportsWithSignedUrls);
    return {
      ...site,
      reports: reportsWithSignedUrls,
      coReporterNames: coReporterSummaries.map((s) => s.name),
      coReporterSummaries,
      mergedDuplicateChildCountTotal,
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

  async findSiteUpvotes(siteId: string, query: ListSiteUpvotesQueryDto): Promise<{
    data: Array<{
      userId: string;
      displayName: string;
      avatarUrl: string | null;
      upvotedAt: string;
    }>;
    meta: { page: number; limit: number; total: number; hasMore: boolean };
  }> {
    await this.siteEngagement.ensureSiteExists(siteId);
    const where = { siteId };
    const skip = (query.page - 1) * query.limit;
    const [total, votes] = await Promise.all([
      this.prisma.siteVote.count({ where }),
      this.prisma.siteVote.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: query.limit,
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              avatarObjectKey: true,
            },
          },
        },
      }),
    ]);
    const data = await Promise.all(
      votes.map(async (vote) => {
        const displayName =
          `${vote.user.firstName ?? ''} ${vote.user.lastName ?? ''}`.trim() || 'Anonymous';
        const avatarUrl = await this.reportsUploadService.resolveUserAvatarUrl(
          vote.user.avatarObjectKey,
        );
        return {
          userId: vote.user.id,
          displayName,
          avatarUrl,
          upvotedAt: vote.createdAt.toISOString(),
        };
      }),
    );
    const loadedThrough = skip + data.length;
    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        hasMore: loadedThrough < total,
      },
    };
  }

  async findSiteComments(
    siteId: string,
    query: ListSiteCommentsQueryDto,
    user?: AuthenticatedUser,
  ): Promise<{ data: SiteCommentTreeNode[]; meta: { page: number; limit: number; total: number } }> {
    return this.siteComments.findSiteComments(siteId, query, user);
  }

  async createSiteComment(siteId: string, dto: CreateSiteCommentDto, user: AuthenticatedUser) {
    const created = await this.siteComments.createSiteComment(siteId, dto, user);
    this.invalidateFeedCache('comment_created', siteId);
    this.emitSiteNotification(siteId, user.userId, 'COMMENT', 'New comment on a site you follow');
    return created;
  }

  async likeSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    const out = await this.siteComments.likeSiteComment(siteId, commentId, user);
    this.invalidateFeedCache('comment_liked', siteId);
    return out;
  }

  async unlikeSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    const out = await this.siteComments.unlikeSiteComment(siteId, commentId, user);
    this.invalidateFeedCache('comment_unliked', siteId);
    return out;
  }

  async updateSiteComment(
    siteId: string,
    commentId: string,
    dto: UpdateSiteCommentDto,
    user: AuthenticatedUser,
  ) {
    const updated = await this.siteComments.updateSiteComment(siteId, commentId, dto, user);
    this.invalidateFeedCache('comment_updated', siteId);
    return updated;
  }

  async deleteSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    const out = await this.siteComments.deleteSiteComment(siteId, commentId, user);
    this.invalidateFeedCache('comment_deleted', siteId);
    return out;
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
    this.sitesMapQuery.invalidateMapCache('site_status_updated', updated.id);
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
