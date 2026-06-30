import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import Redis from 'ioredis';
import { loadMapConfig } from '../../config/map.config';
import { ObservabilityStore } from '../../observability/observability.store';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class MapLifecycleCronService implements OnModuleInit, OnModuleDestroy {
  private static readonly cfg = loadMapConfig();
  private readonly logger = new Logger(MapLifecycleCronService.name);
  private timer: ReturnType<typeof setInterval> | null = null;
  private static readonly cronEnabled =
    process.env.MAP_LIFECYCLE_CRON_ENABLED !== 'false';
  private static readonly LEADER_LOCK_KEY = 'leader:map-lifecycle-cron';
  private static readonly LEADER_LOCK_TTL_SECONDS = 30;
  private readonly redis = MapLifecycleCronService.cfg.redisUrl
    ? new Redis(MapLifecycleCronService.cfg.redisUrl, { lazyConnect: true })
    : null;
  private leaderRenewTimer: ReturnType<typeof setInterval> | null = null;
  private readonly leaderToken = `${process.pid}:${Math.random().toString(36).slice(2)}`;
  private isLeader = false;

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit(): Promise<void> {
    if (!MapLifecycleCronService.cronEnabled) {
      this.logger.log('map lifecycle cron is disabled for this instance');
      return;
    }
    this.isLeader = await this.acquireLeaderLock();
    if (!this.isLeader) {
      this.logger.log('map lifecycle cron not elected leader on this instance');
      return;
    }
    this.startLeaderLockRenewal();
    this.timer = setInterval(() => {
      void this.refreshHotness();
    }, 60 * 60_000);
    void this.refreshHotness();
  }

  async onModuleDestroy(): Promise<void> {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    if (this.leaderRenewTimer) {
      clearInterval(this.leaderRenewTimer);
      this.leaderRenewTimer = null;
    }
    await this.releaseLeaderLock();
  }

  private async refreshHotness(): Promise<void> {
    try {
      const changed = await this.prisma.$executeRaw`
        UPDATE "MapSiteProjection"
        SET "isHot" = CASE
          WHEN "status" <> 'CLEANED'::"SiteStatus" THEN true
          WHEN "siteUpdatedAt" >= NOW() - interval '90 days' THEN true
          ELSE false
        END,
        "projectedAt" = NOW()
        WHERE "isHot" IS DISTINCT FROM (
          CASE
            WHEN "status" <> 'CLEANED'::"SiteStatus" THEN true
            WHEN "siteUpdatedAt" >= NOW() - interval '90 days' THEN true
            ELSE false
          END
        )
      `;
      if (typeof changed === 'number') {
        ObservabilityStore.recordMapProjectionHotRefresh(changed);
      }
      const [stats] = await this.prisma.$queryRaw<Array<{ rows_total: number; hot_rows: number; oldest_hot_seconds: number | null }>>`
        SELECT
          COUNT(*)::int as rows_total,
          COUNT(*) FILTER (WHERE "isHot" = true)::int as hot_rows,
          EXTRACT(EPOCH FROM (NOW() - MIN("projectedAt") FILTER (WHERE "isHot" = true)))::int as oldest_hot_seconds
        FROM "MapSiteProjection"
      `;
      if (stats) {
        ObservabilityStore.recordMapProjectionSnapshot({
          rowsTotal: Number(stats.rows_total ?? 0),
          hotRows: Number(stats.hot_rows ?? 0),
          stalenessSeconds: stats.oldest_hot_seconds == null ? -1 : Number(stats.oldest_hot_seconds),
        });
      }
    } catch (error) {
      this.logger.warn(`map lifecycle refresh failed: ${String(error)}`);
    }
  }

  private async acquireLeaderLock(): Promise<boolean> {
    if (!this.redis) {
      return process.env.NODE_ENV !== 'production';
    }
    await this.redis.connect().catch(() => undefined);
    const response = await this.redis.set(
      MapLifecycleCronService.LEADER_LOCK_KEY,
      this.leaderToken,
      'EX',
      MapLifecycleCronService.LEADER_LOCK_TTL_SECONDS,
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
          MapLifecycleCronService.LEADER_LOCK_KEY,
          this.leaderToken,
          String(MapLifecycleCronService.LEADER_LOCK_TTL_SECONDS),
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
        MapLifecycleCronService.LEADER_LOCK_KEY,
        this.leaderToken,
      )
      .catch(() => undefined);
  }
}
