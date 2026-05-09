import { HeadBucketCommand } from '@aws-sdk/client-s3';
import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import Redis from 'ioredis';
import { loadFeatureFlags } from '../config/feature-flags';
import { PrismaService } from '../prisma/prisma.service';
import { S3StorageClient } from '../storage/s3-storage.client';

@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3StorageClient,
  ) {}

  @Get()
  liveness(): { status: string } {
    return { status: 'ok' };
  }

  @Get('live')
  live(): { status: string } {
    return { status: 'ok' };
  }

  @Get('ready')
  async readiness(): Promise<{ status: string; redis?: string; s3?: string }> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      throw new ServiceUnavailableException('Database unavailable');
    }

    let redis: string | undefined;
    const redisUrl = process.env.REDIS_URL?.trim();
    if (redisUrl) {
      const client = new Redis(redisUrl, { maxRetriesPerRequest: 1, enableReadyCheck: true });
      try {
        await client.ping();
        redis = 'ok';
      } catch {
        throw new ServiceUnavailableException('Redis unavailable');
      } finally {
        await client.quit();
      }
    } else {
      redis = 'skipped';
    }

    let s3: string | undefined;
    const client = this.s3.getClientOrNull();
    if (!this.s3.enabled || !this.s3.bucket || !client) {
      s3 = 'skipped';
    } else {
      try {
        await client.send(new HeadBucketCommand({ Bucket: this.s3.bucket }));
        s3 = 'ok';
      } catch {
        throw new ServiceUnavailableException('S3 unavailable');
      }
    }

    return { status: 'ok', redis, s3 };
  }

  /**
   * Map pipeline signals for operators (projection freshness, outbox depth).
   * Always 200 — use `alerts` for non-empty human-readable warnings.
   */
  @Get('map')
  async mapPipeline(): Promise<{
    status: string;
    mapUseProjection: boolean;
    outboxPending: number;
    staleHotProjectionRows: number;
    alerts: string[];
  }> {
    const flags = loadFeatureFlags();
    const alerts: string[] = [];
    const [outboxRow] = await this.prisma.$queryRaw<Array<{ c: bigint }>>`
      SELECT COUNT(*)::bigint AS c
      FROM "MapEventOutbox"
      WHERE "status" = 'PENDING'::"MapEventOutboxStatus"
    `;
    const outboxPending = Number(outboxRow?.c ?? 0n);
    if (outboxPending > 100) {
      alerts.push(`map_outbox_pending_high:${outboxPending}`);
    }

    let staleHotProjectionRows = 0;
    if (flags.mapUseProjection) {
      const rows = await this.prisma.$queryRaw<Array<{ c: bigint }>>`
        SELECT COUNT(*)::bigint AS c
        FROM "MapSiteProjection"
        WHERE "isHot" = true
          AND "projectedAt" < NOW() - INTERVAL '10 minutes'
      `;
      staleHotProjectionRows = Number(rows[0]?.c ?? 0n);
      if (staleHotProjectionRows > 0) {
        alerts.push(`map_projection_stale_hot_rows:${staleHotProjectionRows}`);
      }
    }

    const status = alerts.length === 0 ? 'ok' : 'degraded';
    return {
      status,
      mapUseProjection: flags.mapUseProjection,
      outboxPending,
      staleHotProjectionRows,
      alerts,
    };
  }

  /**
   * Synthetic geospatial read around Skopje (PostGIS when available; bbox fallback).
   * Always 200 — use `alerts` when latency exceeds budget or PostGIS path failed.
   */
  @Get('map-deep')
  async mapDeep(): Promise<{
    status: string;
    durationMs: number;
    matchCount: number;
    queryPath: 'postgis_dwithin' | 'bbox_fallback' | 'error';
    alerts: string[];
  }> {
    const alerts: string[] = [];
    const t0 = Date.now();
    try {
      const [row] = await this.prisma.$queryRaw<Array<{ c: bigint }>>`
        SELECT COUNT(*)::bigint AS c
        FROM "Site"
        WHERE ST_DWithin(
          ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography,
          ST_SetSRID(ST_MakePoint(21.4333, 41.9973), 4326)::geography,
          5000
        )
      `;
      const durationMs = Date.now() - t0;
      const matchCount = Number(row?.c ?? 0n);
      if (durationMs > 250) {
        alerts.push(`map_deep_query_slow:${durationMs}ms`);
      }
      return {
        status: alerts.length > 0 ? 'degraded' : 'ok',
        durationMs,
        matchCount,
        queryPath: 'postgis_dwithin',
        alerts,
      };
    } catch {
      try {
        const t1 = Date.now();
        const [row] = await this.prisma.$queryRaw<Array<{ c: bigint }>>`
          SELECT COUNT(*)::bigint AS c
          FROM "Site"
          WHERE "latitude" BETWEEN 41.9 AND 42.1
            AND "longitude" BETWEEN 21.3 AND 21.6
        `;
        const durationMs = Date.now() - t1;
        alerts.push('map_deep_postgis_unavailable_bbox_fallback');
        if (durationMs > 250) {
          alerts.push(`map_deep_query_slow:${durationMs}ms`);
        }
        return {
          status: 'degraded',
          durationMs,
          matchCount: Number(row?.c ?? 0n),
          queryPath: 'bbox_fallback',
          alerts,
        };
      } catch {
        alerts.push('map_deep_query_failed');
        return {
          status: 'degraded',
          durationMs: Date.now() - t0,
          matchCount: 0,
          queryPath: 'error',
          alerts,
        };
      }
    }
  }
}
