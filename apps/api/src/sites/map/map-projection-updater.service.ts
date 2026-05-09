import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import Redis from 'ioredis';
import { Subscription } from 'rxjs';
import { loadMapConfig } from '../../config/map.config';
import { SiteEventsService } from '../../admin-events/site-events.service';
import { PrismaService } from '../../prisma/prisma.service';

type ProjectionSourceSite = {
  id: string;
  createdAt: Date;
  updatedAt: Date;
  latitude: number;
  longitude: number;
  address: string | null;
  description: string | null;
  status: string;
  upvotesCount: number;
  commentsCount: number;
  savesCount: number;
  sharesCount: number;
  isArchivedByAdmin: boolean;
  archivedAt: Date | null;
  reports: Array<{
    title: string;
    description: string | null;
    category: string | null;
    reportNumber: string | null;
    createdAt: Date;
    mediaUrls: string[];
  }>;
  _count: { reports: number };
};

@Injectable()
export class MapProjectionUpdaterService implements OnModuleInit, OnModuleDestroy {
  private static readonly cfg = loadMapConfig();
  private readonly logger = new Logger(MapProjectionUpdaterService.name);
  private eventSub: Subscription | null = null;
  private reconcileTimer: ReturnType<typeof setInterval> | null = null;
  private readonly refreshDebounceTimers = new Map<string, ReturnType<typeof setTimeout>>();
  private static readonly REFRESH_DEBOUNCE_MS = 500;
  private static readonly projectionWorkerEnabled =
    process.env.MAP_PROJECTION_WORKER_ENABLED !== 'false';
  private static readonly LEADER_LOCK_KEY = 'leader:map-projection-updater';
  private static readonly LEADER_LOCK_TTL_SECONDS = 30;
  private readonly redis = MapProjectionUpdaterService.cfg.redisUrl
    ? new Redis(MapProjectionUpdaterService.cfg.redisUrl, { lazyConnect: true })
    : null;
  private leaderRenewTimer: ReturnType<typeof setInterval> | null = null;
  private readonly leaderToken = `${process.pid}:${Math.random().toString(36).slice(2)}`;
  private isLeader = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly siteEvents: SiteEventsService,
  ) {}

  async onModuleInit(): Promise<void> {
    if (!MapProjectionUpdaterService.projectionWorkerEnabled) {
      this.logger.log('map projection worker is disabled for this instance');
      return;
    }
    this.isLeader = await this.acquireLeaderLock();
    if (!this.isLeader) {
      this.logger.log('map projection worker not elected leader on this instance');
      return;
    }
    this.startLeaderLockRenewal();
    this.eventSub = this.siteEvents.getEvents().subscribe((event) => {
      this.scheduleSiteProjectionRefresh(event.siteId);
    });
    this.reconcileTimer = setInterval(() => {
      void this.rebuildHotProjection();
    }, 15 * 60_000);
    void this.rebuildHotProjection();
  }

  async onModuleDestroy(): Promise<void> {
    if (this.leaderRenewTimer) {
      clearInterval(this.leaderRenewTimer);
      this.leaderRenewTimer = null;
    }
    this.eventSub?.unsubscribe();
    this.eventSub = null;
    if (this.reconcileTimer) {
      clearInterval(this.reconcileTimer);
      this.reconcileTimer = null;
    }
    for (const timer of this.refreshDebounceTimers.values()) {
      clearTimeout(timer);
    }
    this.refreshDebounceTimers.clear();
    await this.releaseLeaderLock();
  }

  async rebuildHotProjection(): Promise<void> {
    let cursor: string | undefined;
    const batch = 200;
    try {
      while (true) {
        const sites = (await this.prisma.site.findMany({
          where: cursor ? { id: { gt: cursor } } : {},
          orderBy: { id: 'asc' },
          take: batch,
          include: {
            reports: {
              orderBy: { createdAt: 'desc' },
              take: 1,
              select: {
                title: true,
                description: true,
                category: true,
                reportNumber: true,
                createdAt: true,
                mediaUrls: true,
              },
            },
            _count: { select: { reports: true } },
          },
        })) as ProjectionSourceSite[];
        if (sites.length === 0) break;
        const operations = sites.map((site) => {
          const latest = site.reports[0];
          const thumbnail = latest?.mediaUrls?.[0] ?? null;
          const isHot =
            site.status !== 'CLEANED' ||
            site.updatedAt.getTime() > Date.now() - 90 * 24 * 60 * 60 * 1000;
          return this.upsertProjectionRow({
            siteId: site.id,
            latitude: site.latitude,
            longitude: site.longitude,
            status: site.status,
            address: site.address,
            description: site.description,
            thumbnailUrl: thumbnail,
            pollutionCategory: latest?.category ?? null,
            latestReportTitle: latest?.title ?? null,
            latestReportDescription: latest?.description ?? null,
            latestReportNumber: latest?.reportNumber ?? null,
            reportCount: site._count.reports,
            upvotesCount: site.upvotesCount,
            commentsCount: site.commentsCount,
            savesCount: site.savesCount,
            sharesCount: site.sharesCount,
            latestReportAt: latest?.createdAt ?? null,
            siteCreatedAt: site.createdAt,
            siteUpdatedAt: site.updatedAt,
            isHot,
            isArchivedByAdmin: site.isArchivedByAdmin,
            archivedAt: site.archivedAt,
          });
        });
        await Promise.all(operations);
        cursor = sites[sites.length - 1].id;
      }
    } catch (error) {
      this.logger.warn(`map projection rebuild failed: ${String(error)}`);
    }
  }

  async refreshSiteProjection(siteId: string): Promise<void> {
    try {
      const site = (await this.prisma.site.findUnique({
        where: { id: siteId },
        include: {
          reports: {
            orderBy: { createdAt: 'desc' },
            take: 1,
            select: {
              title: true,
              description: true,
              category: true,
              reportNumber: true,
              createdAt: true,
              mediaUrls: true,
            },
          },
          _count: { select: { reports: true } },
        },
      })) as ProjectionSourceSite | null;
      if (!site) {
        await this.prisma.$executeRaw`DELETE FROM "MapSiteProjection" WHERE "siteId" = ${siteId}`;
        return;
      }
      const latest = site.reports[0];
      const isHot =
        site.status !== 'CLEANED' ||
        site.updatedAt.getTime() > Date.now() - 90 * 24 * 60 * 60 * 1000;
      await this.upsertProjectionRow({
        siteId: site.id,
        latitude: site.latitude,
        longitude: site.longitude,
        status: site.status,
        address: site.address,
        description: site.description,
        thumbnailUrl: latest?.mediaUrls?.[0] ?? null,
        pollutionCategory: latest?.category ?? null,
        latestReportTitle: latest?.title ?? null,
        latestReportDescription: latest?.description ?? null,
        latestReportNumber: latest?.reportNumber ?? null,
        reportCount: site._count.reports,
        upvotesCount: site.upvotesCount,
        commentsCount: site.commentsCount,
        savesCount: site.savesCount,
        sharesCount: site.sharesCount,
        latestReportAt: latest?.createdAt ?? null,
        siteCreatedAt: site.createdAt,
        siteUpdatedAt: site.updatedAt,
        isHot,
        isArchivedByAdmin: site.isArchivedByAdmin,
        archivedAt: site.archivedAt,
      });
    } catch (error) {
      this.logger.warn(`map projection refresh failed for ${siteId}: ${String(error)}`);
    }
  }

  private scheduleSiteProjectionRefresh(siteId: string): void {
    const existing = this.refreshDebounceTimers.get(siteId);
    if (existing) {
      clearTimeout(existing);
    }
    const timer = setTimeout(() => {
      this.refreshDebounceTimers.delete(siteId);
      void this.refreshSiteProjection(siteId);
    }, MapProjectionUpdaterService.REFRESH_DEBOUNCE_MS);
    this.refreshDebounceTimers.set(siteId, timer);
  }

  private async acquireLeaderLock(): Promise<boolean> {
    if (!this.redis) {
      return process.env.NODE_ENV !== 'production';
    }
    await this.redis.connect().catch(() => undefined);
    const response = await this.redis.set(
      MapProjectionUpdaterService.LEADER_LOCK_KEY,
      this.leaderToken,
      'EX',
      MapProjectionUpdaterService.LEADER_LOCK_TTL_SECONDS,
      'NX',
    );
    return response === 'OK';
  }

  private startLeaderLockRenewal(): void {
    if (!this.redis) {
      return;
    }
    const redis = this.redis;
    this.leaderRenewTimer = setInterval(() => {
      void redis
        .eval(
          `
          if redis.call("GET", KEYS[1]) == ARGV[1] then
            return redis.call("EXPIRE", KEYS[1], ARGV[2])
          end
          return 0
          `,
          1,
          MapProjectionUpdaterService.LEADER_LOCK_KEY,
          this.leaderToken,
          String(MapProjectionUpdaterService.LEADER_LOCK_TTL_SECONDS),
        )
        .catch(() => undefined);
    }, 10_000);
  }

  private async releaseLeaderLock(): Promise<void> {
    if (!this.redis || !this.isLeader) {
      return;
    }
    await this.redis.connect().catch(() => undefined);
    await this.redis
      .eval(
        `
        if redis.call("GET", KEYS[1]) == ARGV[1] then
          return redis.call("DEL", KEYS[1])
        end
        return 0
        `,
        1,
        MapProjectionUpdaterService.LEADER_LOCK_KEY,
        this.leaderToken,
      )
      .catch(() => undefined);
  }

  private async upsertProjectionRow(row: {
    siteId: string;
    latitude: number;
    longitude: number;
    status: string;
    address: string | null;
    description: string | null;
    thumbnailUrl: string | null;
    pollutionCategory: string | null;
    latestReportTitle: string | null;
    latestReportDescription: string | null;
    latestReportNumber: string | null;
    reportCount: number;
    upvotesCount: number;
    commentsCount: number;
    savesCount: number;
    sharesCount: number;
    latestReportAt: Date | null;
    siteCreatedAt: Date;
    siteUpdatedAt: Date;
    isHot: boolean;
    isArchivedByAdmin: boolean;
    archivedAt: Date | null;
  }): Promise<void> {
    await this.prisma.$executeRaw`
      INSERT INTO "MapSiteProjection" (
        "siteId","latitude","longitude","status","address","description","thumbnailUrl",
        "pollutionCategory","latestReportTitle","latestReportDescription","latestReportNumber",
        "reportCount","upvotesCount","commentsCount","savesCount","sharesCount",
        "latestReportAt","siteCreatedAt","siteUpdatedAt","projectedAt","isHot","isArchivedByAdmin","archivedAt"
      ) VALUES (
        ${row.siteId},${row.latitude},${row.longitude},${row.status}::"SiteStatus",${row.address},${row.description},${row.thumbnailUrl},
        ${row.pollutionCategory},${row.latestReportTitle},${row.latestReportDescription},${row.latestReportNumber},
        ${row.reportCount},${row.upvotesCount},${row.commentsCount},${row.savesCount},${row.sharesCount},
        ${row.latestReportAt},${row.siteCreatedAt},${row.siteUpdatedAt},NOW(),${row.isHot},${row.isArchivedByAdmin},${row.archivedAt}
      )
      ON CONFLICT ("siteId") DO UPDATE
      SET
        "latitude" = EXCLUDED."latitude",
        "longitude" = EXCLUDED."longitude",
        "status" = EXCLUDED."status",
        "address" = EXCLUDED."address",
        "description" = EXCLUDED."description",
        "thumbnailUrl" = EXCLUDED."thumbnailUrl",
        "pollutionCategory" = EXCLUDED."pollutionCategory",
        "latestReportTitle" = EXCLUDED."latestReportTitle",
        "latestReportDescription" = EXCLUDED."latestReportDescription",
        "latestReportNumber" = EXCLUDED."latestReportNumber",
        "reportCount" = EXCLUDED."reportCount",
        "upvotesCount" = EXCLUDED."upvotesCount",
        "commentsCount" = EXCLUDED."commentsCount",
        "savesCount" = EXCLUDED."savesCount",
        "sharesCount" = EXCLUDED."sharesCount",
        "latestReportAt" = EXCLUDED."latestReportAt",
        "siteCreatedAt" = EXCLUDED."siteCreatedAt",
        "siteUpdatedAt" = EXCLUDED."siteUpdatedAt",
        "projectedAt" = NOW(),
        "isHot" = EXCLUDED."isHot",
        "isArchivedByAdmin" = EXCLUDED."isArchivedByAdmin",
        "archivedAt" = EXCLUDED."archivedAt";
    `;
  }
}
