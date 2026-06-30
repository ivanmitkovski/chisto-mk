import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import {
  ListSitesQueryDto,
  SiteFeedGeoScope,
  SiteFeedMode,
  SiteFeedSort,
} from '../dto/list-sites-query.dto';
import { decodeFeedCursor } from '../util/sites-feed-cursor.util';
import type { FeedSiteRow, SitesFeedCandidateBundle } from '../types/sites-feed-candidate.types';
import { withTimeout } from '../util/sites-feed-query-async.util';
import { resolveFeedGeoScope } from '../util/sites-feed-geo-scope.util';
import { siteVisibilityPrismaWhere } from '../util/site-visibility.helper';

@Injectable()
export class SitesFeedCandidatesService {
  private readonly feedQueryTimeoutMs = 5_000;

  constructor(private readonly prisma: PrismaService) {}

  async loadCandidateSites(
    query: ListSitesQueryDto,
    user: AuthenticatedUser | undefined,
  ): Promise<SitesFeedCandidateBundle> {
    const scope = resolveFeedGeoScope(query);
    const baseWhere: Prisma.SiteWhereInput = {
      ...(query.status ? { status: query.status } : {}),
      ...siteVisibilityPrismaWhere(user?.userId ?? null),
    };
    const rankedHybrid = query.sort === SiteFeedSort.HYBRID && query.mode !== SiteFeedMode.LATEST;
    const cursorState = decodeFeedCursor(query.cursor, rankedHybrid);
    const candidateLimit = Math.min(300, Math.max(query.limit * 6, query.limit));

    const sites =
      scope === SiteFeedGeoScope.DISCOVERY
        ? await this.loadDiscoveryCandidates(query, user, baseWhere, candidateLimit)
        : await this.loadLocalCandidates(
            query,
            user,
            baseWhere,
            candidateLimit,
            cursorState?.dbClause ?? null,
          );

    return this.buildCandidateBundle(sites, baseWhere);
  }

  private async loadLocalCandidates(
    query: ListSitesQueryDto,
    user: AuthenticatedUser | undefined,
    baseWhere: Prisma.SiteWhereInput,
    candidateLimit: number,
    cursorClause: Prisma.SiteWhereInput | null,
  ): Promise<FeedSiteRow[]> {
    const where = this.applyGeoBoundingBox(query, { ...baseWhere });
    const feedWhere: Prisma.SiteWhereInput = cursorClause ? { AND: [where, cursorClause] } : where;
    return this.fetchSiteRows(feedWhere, candidateLimit, user);
  }

  private async loadDiscoveryCandidates(
    query: ListSitesQueryDto,
    user: AuthenticatedUser | undefined,
    baseWhere: Prisma.SiteWhereInput,
    candidateLimit: number,
  ): Promise<FeedSiteRow[]> {
    const retrieverTake = Math.min(200, candidateLimit);
    const include = this.buildSiteInclude(user);
    const trendingCutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const retrieverQueries: Array<Promise<FeedSiteRow[]>> = [
      this.fetchSiteRowsWithInclude(
        baseWhere,
        retrieverTake,
        include,
        [{ createdAt: 'desc' }, { id: 'desc' }],
      ),
      this.fetchSiteRowsWithInclude(
        { ...baseWhere, createdAt: { gte: trendingCutoff } },
        retrieverTake,
        include,
        [
          { sharesCount: 'desc' },
          { upvotesCount: 'desc' },
          { commentsCount: 'desc' },
          { createdAt: 'desc' },
        ],
      ),
    ];

    if (query.lat != null && query.lng != null) {
      const nearbyWhere = this.applyGeoBoundingBox(query, { ...baseWhere });
      retrieverQueries.push(
        this.fetchSiteRowsWithInclude(
          nearbyWhere,
          retrieverTake,
          include,
          [{ createdAt: 'desc' }, { id: 'desc' }],
        ),
      );
    }

    const batches = await Promise.all(retrieverQueries);
    const merged = new Map<string, FeedSiteRow>();
    for (const batch of batches) {
      for (const row of batch) {
        if (!merged.has(row.id)) {
          merged.set(row.id, row);
        }
      }
    }
    return [...merged.values()].slice(0, candidateLimit);
  }

  private applyGeoBoundingBox(
    query: ListSitesQueryDto,
    where: Prisma.SiteWhereInput,
  ): Prisma.SiteWhereInput {
    if (query.lat == null || query.lng == null) {
      return where;
    }
    const radiusMeters = (query.radiusKm ?? 10) * 1000;
    const metersPerDegreeLat = 111_320;
    const deltaLat = radiusMeters / metersPerDegreeLat;
    const metersPerDegreeLng =
      Math.cos((query.lat * Math.PI) / 180) * metersPerDegreeLat || metersPerDegreeLat;
    const deltaLng = radiusMeters / metersPerDegreeLng;

    return {
      ...where,
      latitude: {
        gte: query.lat - deltaLat,
        lte: query.lat + deltaLat,
      },
      longitude: {
        gte: query.lng - deltaLng,
        lte: query.lng + deltaLng,
      },
    };
  }

  private buildSiteInclude(user: AuthenticatedUser | undefined): Prisma.SiteInclude {
    return {
      heroReport: {
        select: { mediaUrls: true },
      },
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
            select: { id: true, firstName: true, lastName: true, avatarObjectKey: true, status: true },
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
    };
  }

  private async fetchSiteRows(
    where: Prisma.SiteWhereInput,
    take: number,
    user: AuthenticatedUser | undefined,
  ): Promise<FeedSiteRow[]> {
    return this.fetchSiteRowsWithInclude(
      where,
      take,
      this.buildSiteInclude(user),
      [{ createdAt: 'desc' }, { id: 'desc' }],
    );
  }

  private async fetchSiteRowsWithInclude(
    where: Prisma.SiteWhereInput,
    take: number,
    include: Prisma.SiteInclude,
    orderBy: Prisma.SiteOrderByWithRelationInput[],
  ): Promise<FeedSiteRow[]> {
    return (await withTimeout(
      this.prisma.site.findMany({
        where,
        orderBy,
        take,
        include,
      }),
      this.feedQueryTimeoutMs,
      'Feed query timed out',
    )) as unknown as FeedSiteRow[];
  }

  private async buildCandidateBundle(
    sites: FeedSiteRow[],
    where: Prisma.SiteWhereInput,
  ): Promise<SitesFeedCandidateBundle> {
    const siteIds = sites.map((s) => s.id);
    const recentCutoff = new Date(Date.now() - 2 * 60 * 60 * 1000);
    const [recentVotes, recentSaves, recentShares] =
      siteIds.length > 0
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

    return { sites, velocityBySite, duplicateTitleCounts, where };
  }
}
