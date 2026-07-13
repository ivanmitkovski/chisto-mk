import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { ObservabilityStore } from '../../observability/observability.store';
import { S3StorageClient } from '../util/s3-storage.client';

const DEFAULT_REPORT_MEDIA_SIGNED_URL_TTL_SECONDS = 15 * 60;
const REDIS_CACHE_PREFIX = 'signedurl:report:';
const CACHE_SKEW_MS = 30_000;

/** Parse SigV4 presign expiry from query (X-Amz-Date + X-Amz-Expires). */
export function presignedUrlExpiresAtMs(url: string): number | null {
  try {
    const u = new URL(url);
    const amzDate = u.searchParams.get('X-Amz-Date');
    const expiresSec = Number(u.searchParams.get('X-Amz-Expires') ?? '0');
    if (!amzDate || !Number.isFinite(expiresSec) || expiresSec <= 0) {
      return null;
    }
    const y = Number(amzDate.slice(0, 4));
    const mo = Number(amzDate.slice(4, 6)) - 1;
    const d = Number(amzDate.slice(6, 8));
    const h = Number(amzDate.slice(9, 11));
    const mi = Number(amzDate.slice(11, 13));
    const s = Number(amzDate.slice(13, 15));
    const signedMs = Date.UTC(y, mo, d, h, mi, s);
    if (!Number.isFinite(signedMs)) {
      return null;
    }
    return signedMs + expiresSec * 1000;
  } catch {
    return null;
  }
}

function cacheExpiresAtMs(url: string, fallbackMs: number): number {
  const urlExpiry = presignedUrlExpiresAtMs(url);
  if (urlExpiry != null) {
    return urlExpiry - CACHE_SKEW_MS;
  }
  return fallbackMs;
}

/** SECURITY: Report media presigned URLs — short TTL limits exposure if leaked. */
@Injectable()
export class ReportMediaSignedUrlService implements OnModuleDestroy {
  private readonly logger = new Logger(ReportMediaSignedUrlService.name);
  private readonly memoryCache = new Map<string, { url: string; expiresAt: number }>();
  private readonly inFlight = new Map<string, Promise<string | null>>();
  private readonly redis: Redis | null;
  private readonly ttlSeconds: number;

  constructor(
    private readonly s3: S3StorageClient,
    configService: ConfigService,
  ) {
    const redisUrl = process.env.REDIS_URL?.trim();
    this.redis =
      redisUrl && redisUrl.length > 0
        ? new Redis(redisUrl, { maxRetriesPerRequest: 1, enableReadyCheck: true })
        : null;
    const raw = configService.get<string>('REPORT_MEDIA_SIGNED_URL_TTL_SECONDS');
    const parsed = raw != null ? Number.parseInt(String(raw).trim(), 10) : NaN;
    this.ttlSeconds =
      Number.isFinite(parsed) && parsed >= 60 && parsed <= 3600
        ? parsed
        : DEFAULT_REPORT_MEDIA_SIGNED_URL_TTL_SECONDS;
  }

  getSignedUrlTtlSeconds(): number {
    return this.ttlSeconds;
  }

  async onModuleDestroy(): Promise<void> {
    if (this.redis) {
      await this.redis.quit().catch(() => undefined);
    }
  }

  private cacheKeyForObjectKey(key: string): string {
    return `${REDIS_CACHE_PREFIX}${key}`;
  }

  private isUrlStillValid(url: string, nowMs: number): boolean {
    const expiry = presignedUrlExpiresAtMs(url);
    if (expiry == null) {
      return false;
    }
    return expiry > nowMs + CACHE_SKEW_MS;
  }

  async getSignedGetUrl(objectKey: string, nowMs: number = Date.now()): Promise<string | null> {
    const inflight = this.inFlight.get(objectKey);
    if (inflight) {
      return inflight;
    }
    const promise = this.resolveSignedGetUrl(objectKey, nowMs).finally(() => {
      this.inFlight.delete(objectKey);
    });
    this.inFlight.set(objectKey, promise);
    return promise;
  }

  private async resolveSignedGetUrl(objectKey: string, nowMs: number): Promise<string | null> {
    const client = this.s3.getClientOrNull();
    const bucket = this.s3.bucket;
    if (!client || !bucket || !this.s3.enabled) {
      return null;
    }

    const mem = this.memoryCache.get(objectKey);
    if (mem && mem.expiresAt > nowMs && this.isUrlStillValid(mem.url, nowMs)) {
      ObservabilityStore.recordReportSignedUrl('cache_hit');
      return mem.url;
    }
    if (mem) {
      this.memoryCache.delete(objectKey);
    }

    if (this.redis) {
      try {
        const hit = await this.redis.get(this.cacheKeyForObjectKey(objectKey));
        if (hit && this.isUrlStillValid(hit, nowMs)) {
          this.memoryCache.set(objectKey, {
            url: hit,
            expiresAt: cacheExpiresAtMs(hit, nowMs + this.ttlSeconds * 1000),
          });
          ObservabilityStore.recordReportSignedUrl('cache_hit');
          return hit;
        }
        if (hit) {
          void this.redis.del(this.cacheKeyForObjectKey(objectKey)).catch(() => undefined);
        }
      } catch {
        // Redis optional — fall through to S3 presign.
      }
    }

    const started = Date.now();
    try {
      const signed = await getSignedUrl(
        client,
        new GetObjectCommand({
          Bucket: bucket,
          Key: objectKey,
          ResponseContentDisposition: 'inline',
          ResponseContentType: ReportMediaSignedUrlService.contentTypeForKey(objectKey),
        }),
        { expiresIn: this.ttlSeconds },
      );
      const expiresAt = cacheExpiresAtMs(signed, nowMs + this.ttlSeconds * 1000);
      this.memoryCache.set(objectKey, { url: signed, expiresAt });
      if (this.redis) {
        const redisTtl = Math.max(60, this.ttlSeconds - 60);
        void this.redis
          .set(this.cacheKeyForObjectKey(objectKey), signed, 'EX', redisTtl)
          .catch(() => undefined);
      }
      ObservabilityStore.recordReportSignedUrl('issued');
      ObservabilityStore.recordReportSignedUrlLatencyMs(Date.now() - started);
      return signed;
    } catch (err) {
      this.logger.warn(`report_media.sign_failed key=${objectKey} err=${(err as Error).message}`);
      ObservabilityStore.recordReportSignedUrl('error');
      return null;
    }
  }

  invalidateKey(objectKey: string): void {
    this.memoryCache.delete(objectKey);
    if (this.redis) {
      void this.redis.del(this.cacheKeyForObjectKey(objectKey)).catch(() => undefined);
    }
  }

  private static contentTypeForKey(key: string): string {
    const lower = key.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
