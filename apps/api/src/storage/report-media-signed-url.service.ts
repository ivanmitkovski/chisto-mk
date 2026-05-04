import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import { ObservabilityStore } from '../observability/observability.store';
import { S3StorageClient } from './s3-storage.client';

const REPORT_MEDIA_SIGNED_URL_TTL_SECONDS = 5 * 60;
const REDIS_CACHE_PREFIX = 'signedurl:report:';
const REDIS_TTL_SECONDS = Math.max(60, REPORT_MEDIA_SIGNED_URL_TTL_SECONDS - 120);

/** SECURITY: Report media presigned URLs — short TTL limits exposure if leaked. */
@Injectable()
export class ReportMediaSignedUrlService implements OnModuleDestroy {
  private readonly logger = new Logger(ReportMediaSignedUrlService.name);
  private readonly memoryCache = new Map<string, { url: string; expiresAt: number }>();
  private readonly redis: Redis | null;

  constructor(private readonly s3: S3StorageClient) {
    const redisUrl = process.env.REDIS_URL?.trim();
    this.redis =
      redisUrl && redisUrl.length > 0
        ? new Redis(redisUrl, { maxRetriesPerRequest: 1, enableReadyCheck: true })
        : null;
  }

  async onModuleDestroy(): Promise<void> {
    if (this.redis) {
      await this.redis.quit().catch(() => undefined);
    }
  }

  private cacheKeyForObjectKey(key: string): string {
    return `${REDIS_CACHE_PREFIX}${key}`;
  }

  async getSignedGetUrl(objectKey: string, nowMs: number = Date.now()): Promise<string | null> {
    const client = this.s3.getClientOrNull();
    const bucket = this.s3.bucket;
    if (!client || !bucket || !this.s3.enabled) {
      return null;
    }

    const mem = this.memoryCache.get(objectKey);
    if (mem && mem.expiresAt > nowMs) {
      ObservabilityStore.recordReportSignedUrl('cache_hit');
      return mem.url;
    }

    if (this.redis) {
      try {
        const hit = await this.redis.get(this.cacheKeyForObjectKey(objectKey));
        if (hit) {
          this.memoryCache.set(objectKey, {
            url: hit,
            expiresAt: nowMs + (REPORT_MEDIA_SIGNED_URL_TTL_SECONDS - 60) * 1000,
          });
          ObservabilityStore.recordReportSignedUrl('cache_hit');
          return hit;
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
          ResponseContentDisposition: 'attachment; filename="evidence.jpg"',
          ResponseContentType: ReportMediaSignedUrlService.contentTypeForKey(objectKey),
        }),
        { expiresIn: REPORT_MEDIA_SIGNED_URL_TTL_SECONDS },
      );
      const expiresAt = nowMs + (REPORT_MEDIA_SIGNED_URL_TTL_SECONDS - 60) * 1000;
      this.memoryCache.set(objectKey, { url: signed, expiresAt });
      if (this.redis) {
        void this.redis
          .set(this.cacheKeyForObjectKey(objectKey), signed, 'EX', REDIS_TTL_SECONDS)
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
