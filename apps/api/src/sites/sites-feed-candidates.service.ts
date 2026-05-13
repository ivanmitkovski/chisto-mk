import { Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ListSitesQueryDto, SiteFeedMode, SiteFeedSort } from './dto/list-sites-query.dto';
import { decodeFeedCursor } from './sites-feed-cursor.util';
import type { FeedSiteRow, SitesFeedCandidateBundle } from './sites-feed-candidate.types';
import { withTimeout } from './sites-feed-query-async.util';

@Injectable()
export class SitesFeedCandidatesService {
  private readonly feedQueryTimeoutMs = 5_000;

  constructor(private readonly prisma: PrismaService) {}

  async loadCandidateSites(
    query: ListSitesQueryDto,
    user: AuthenticatedUser | undefined,
  ): Promise<SitesFeedCandidateBundle> {
    const where: Prisma.SiteWhereInput = query.status ? { status: query.status } : {};

    const hasGeo = query.lat != null && query.lng != null;
    if (hasGeo) {
      const radiusMeters = (query.radiusKm ?? 10) * 1000;
      const metersPerDegreeLat = 111_320;
      const deltaLat = radiusMeters / metersPerDegreeLat;
      const metersPerDegreeLng =
        Math.cos((query.lat! * Math.PI) / 180) * metersPerDegreeLat || metersPerDegreeLat;
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
    const cursorState = decodeFeedCursor(query.cursor, rankedHybrid);
    const cursorClause = cursorState?.dbClause ?? null;
    const feedWhere: Prisma.SiteWhereInput = cursorClause ? { AND: [where, cursorClause] } : where;
    const candidateLimit = Math.min(300, Math.max(query.limit * 6, query.limit));
    const sites = (await withTimeout(
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
    )) as FeedSiteRow[];

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

    return { sites, velocityBySite, duplicateTitleCounts, where };
  }
}
