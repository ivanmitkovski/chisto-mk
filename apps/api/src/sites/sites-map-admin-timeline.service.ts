import { Injectable } from '@nestjs/common';
import Redis from 'ioredis';
import { loadFeatureFlags } from '../config/feature-flags';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SitesMapAdminTimelineService {
  private timelineRedis: Redis | null | undefined;

  constructor(private readonly prisma: PrismaService) {}

  async getAdminMapTimeline(at?: string) {
    const flags = loadFeatureFlags();
    if (!flags.mapAdminTimeMachine) {
      return {
        at: at ?? new Date().toISOString(),
        revisionCount: 0,
        hint: 'Enable MAP_ADMIN_TIME_MACHINE for replay-backed responses.',
      };
    }

    const refDate = at ? new Date(at) : new Date();
    const roundedAtMs = Math.floor(refDate.getTime() / (5 * 60 * 1000)) * 5 * 60 * 1000;
    const roundedAt = new Date(roundedAtMs);
    const cacheKey = `map:admin:timeline:${roundedAt.toISOString()}`;
    const redis = this.getTimelineRedis();
    if (redis) {
      const cached = await redis.get(cacheKey);
      if (cached) {
        return JSON.parse(cached) as {
          at: string;
          buckets: Array<{ timestamp: string; eventCount: number; sampleSiteIds: string[] }>;
          totalRevisions: number;
        };
      }
    }
    const refIso = refDate.toISOString();
    const windowStart = new Date(refDate.getTime() - 24 * 60 * 60 * 1000);

    interface OutboxBucketRow {
      bucket: Date;
      eventCount: number;
      allSiteIds: string[] | null;
    }

    const rows = await this.prisma.$queryRaw<OutboxBucketRow[]>`
      SELECT
        date_trunc('hour', "createdAt") +
          (floor(extract(minute from "createdAt") / 15) * interval '15 minutes') AS bucket,
        COUNT(*)::int AS "eventCount",
        ARRAY_AGG(DISTINCT "siteId") FILTER (WHERE "siteId" IS NOT NULL) AS "allSiteIds"
      FROM "MapEventOutbox"
      WHERE "createdAt" BETWEEN ${windowStart} AND ${refDate}
      GROUP BY 1
      ORDER BY 1 DESC
    `;

    const buckets = rows.map((row) => ({
      timestamp: row.bucket.toISOString(),
      eventCount: row.eventCount,
      sampleSiteIds: (row.allSiteIds ?? []).slice(0, 5),
    }));

    const totalRevisions = buckets.reduce((sum, b) => sum + b.eventCount, 0);

    const response = { at: refIso, buckets, totalRevisions };
    if (redis) {
      await redis.set(cacheKey, JSON.stringify(response), 'EX', 300);
    }
    return response;
  }

  private getTimelineRedis(): Redis | null {
    if (this.timelineRedis !== undefined) {
      return this.timelineRedis;
    }
    const redisUrl = process.env.REDIS_URL?.trim();
    if (!redisUrl) {
      this.timelineRedis = null;
      return null;
    }
    this.timelineRedis = new Redis(redisUrl, {
      maxRetriesPerRequest: 1,
      enableReadyCheck: true,
    });
    return this.timelineRedis;
  }
}
