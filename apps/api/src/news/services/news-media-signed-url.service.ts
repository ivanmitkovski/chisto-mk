import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { S3StorageClient } from '../../storage/util/s3-storage.client';
import {
  cacheEntryExpiresAtMs,
  effectivePresignTtlSeconds,
  isCachedNewsSignedUrlStillValid,
  parseCachedNewsSignedUrl,
  serializeCachedNewsSignedUrl,
} from './news-media-signed-url.cache';

const DEFAULT_NEWS_MEDIA_SIGNED_URL_TTL_SECONDS = 60 * 60;
const REDIS_CACHE_PREFIX = 'signedurl:news:';
const CACHE_SKEW_MS = 30_000;

@Injectable()
export class NewsMediaSignedUrlService implements OnModuleDestroy {
  private readonly logger = new Logger(NewsMediaSignedUrlService.name);
  private readonly memoryCache = new Map<
    string,
    { url: string; expiresAt: number; credentialExpiresAt: number | null }
  >();
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
    const raw = configService.get<string>('NEWS_MEDIA_SIGNED_URL_TTL_SECONDS');
    const parsed = raw != null ? Number.parseInt(String(raw).trim(), 10) : NaN;
    this.ttlSeconds =
      Number.isFinite(parsed) && parsed >= 60 && parsed <= 86400
        ? parsed
        : DEFAULT_NEWS_MEDIA_SIGNED_URL_TTL_SECONDS;
  }

  /** Configured (or default) signed GET URL lifetime in seconds. */
  getSignedUrlTtlSeconds(): number {
    return this.ttlSeconds;
  }

  async onModuleDestroy(): Promise<void> {
    if (this.redis) {
      await this.redis.quit().catch(() => undefined);
    }
  }

  async signMany(objectKeys: string[]): Promise<Map<string, string | null>> {
    const unique = [...new Set(objectKeys.filter((k) => k.length > 0))];
    const entries = await Promise.all(
      unique.map(async (key) => [key, await this.getSignedGetUrl(key)] as const),
    );
    return new Map(entries);
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

  private cacheKeyForObjectKey(key: string): string {
    return `${REDIS_CACHE_PREFIX}${key}`;
  }

  private async resolveSignedGetUrl(objectKey: string, nowMs: number): Promise<string | null> {
    const client = this.s3.getClientOrNull();
    const bucket = this.s3.bucket;
    if (!client || !bucket || !this.s3.enabled) {
      return null;
    }

    const mem = this.memoryCache.get(objectKey);
    if (mem && mem.expiresAt > nowMs) {
      const cachedEntry = { url: mem.url, credentialExpiresAt: mem.credentialExpiresAt };
      if (isCachedNewsSignedUrlStillValid(cachedEntry, nowMs, CACHE_SKEW_MS)) {
        return mem.url;
      }
    }
    if (mem) {
      this.memoryCache.delete(objectKey);
    }

    if (this.redis) {
      try {
        const hit = await this.redis.get(this.cacheKeyForObjectKey(objectKey));
        const cachedEntry = hit ? parseCachedNewsSignedUrl(hit) : null;
        if (cachedEntry && isCachedNewsSignedUrlStillValid(cachedEntry, nowMs, CACHE_SKEW_MS)) {
          this.memoryCache.set(objectKey, {
            url: cachedEntry.url,
            credentialExpiresAt: cachedEntry.credentialExpiresAt,
            expiresAt: cacheEntryExpiresAtMs(
              cachedEntry.url,
              cachedEntry.credentialExpiresAt,
              nowMs,
              this.ttlSeconds,
              CACHE_SKEW_MS,
            ),
          });
          return cachedEntry.url;
        }
      } catch {
        // Redis optional
      }
    }

    try {
      const credentialExpiresAtMs = await this.resolveCredentialExpiresAtMs(client);
      const expiresIn = effectivePresignTtlSeconds(
        this.ttlSeconds,
        credentialExpiresAtMs,
        nowMs,
        CACHE_SKEW_MS,
      );
      const signed = await getSignedUrl(
        client,
        new GetObjectCommand({
          Bucket: bucket,
          Key: objectKey,
          ResponseContentDisposition: 'inline',
          ResponseContentType: NewsMediaSignedUrlService.contentTypeForKey(objectKey),
        }),
        { expiresIn },
      );
      const cacheEntry = {
        url: signed,
        credentialExpiresAt: credentialExpiresAtMs,
      };
      const expiresAt = cacheEntryExpiresAtMs(
        signed,
        credentialExpiresAtMs,
        nowMs,
        expiresIn,
        CACHE_SKEW_MS,
      );
      this.memoryCache.set(objectKey, {
        url: signed,
        credentialExpiresAt: credentialExpiresAtMs,
        expiresAt,
      });
      if (this.redis) {
        const redisTtlSeconds = Math.max(60, Math.ceil((expiresAt - nowMs) / 1000));
        void this.redis
          .set(
            this.cacheKeyForObjectKey(objectKey),
            serializeCachedNewsSignedUrl(cacheEntry),
            'EX',
            redisTtlSeconds,
          )
          .catch(() => undefined);
      }
      return signed;
    } catch (err) {
      this.logger.warn(`news_media.sign_failed key=${objectKey} err=${(err as Error).message}`);
      return null;
    }
  }

  private async resolveCredentialExpiresAtMs(
    client: NonNullable<ReturnType<S3StorageClient['getClientOrNull']>>,
  ): Promise<number | null> {
    try {
      const provider = client.config.credentials;
      if (!provider) {
        return null;
      }
      const credentials = await provider();
      return credentials.expiration?.getTime() ?? null;
    } catch {
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
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'image/jpeg';
  }
}
