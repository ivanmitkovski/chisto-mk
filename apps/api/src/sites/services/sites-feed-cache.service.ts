import { Injectable, Logger } from '@nestjs/common';
import { ObservabilityStore } from '../../observability/observability.store';
import { legacySnapshotGauges } from '../../observability/util/prom-registry';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ListSitesQueryDto } from '../dto/list-sites-query.dto';
import type { SitesFeedListResult } from '../types/sites-feed.types';
import { FeedCacheRedisService } from '../feed/feed-cache-redis.service';

@Injectable()
export class SitesFeedCacheService {
  private readonly logger = new Logger(SitesFeedCacheService.name);

  constructor(private readonly feedRedis: FeedCacheRedisService) {}

  private readonly feedResponseCache = new Map<
    string,
    {
      cachedAt: number;
      value: SitesFeedListResult;
    }
  >();
  private readonly feedCacheSiteIndex = new Map<string, Set<string>>();

  buildFeedCacheKey(query: ListSitesQueryDto, user?: AuthenticatedUser): string {
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
      query.scope,
      query.cursor ?? '',
      query.explain ? 1 : 0,
    ].join('|');
  }

  async get(
    key: string,
  ): Promise<{ cachedAt: number; value: SitesFeedListResult } | undefined> {
    const mem = this.feedResponseCache.get(key);
    if (mem) return mem;
    const raw = await this.feedRedis.get(key);
    if (!raw) return undefined;
    try {
      const parsed = JSON.parse(raw) as SitesFeedListResult;
      const row = { cachedAt: Date.now(), value: parsed };
      this.feedResponseCache.set(key, row);
      legacySnapshotGauges.feedCacheL2Hits.inc();
      return row;
    } catch {
      return undefined;
    }
  }

  async set(key: string, value: SitesFeedListResult, siteIds: string[], nowMs: number): Promise<void> {
    this.feedResponseCache.set(key, { cachedAt: nowMs, value });
    try {
      await this.feedRedis.set(key, JSON.stringify(value));
    } catch (err: unknown) {
      this.logger.warn(`feed Redis set failed key=${key}: ${String(err)}`);
    }
    ObservabilityStore.setFeedCacheEntries(this.feedResponseCache.size);
    this.indexCacheKeySites(key, siteIds);
    if (this.feedResponseCache.size > 300) {
      const oldestKey = this.feedResponseCache.keys().next().value as string | undefined;
      if (oldestKey) this.removeCacheKey(oldestKey);
    }
  }

  invalidate(reason: string, siteId?: string): void {
    ObservabilityStore.recordFeedCacheInvalidation(reason);
    if (siteId) {
      void this.feedRedis.invalidateTag(siteId);
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
    ObservabilityStore.setFeedCacheEntries(0);
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
      this.feedResponseCache.delete(cacheKey);
      ObservabilityStore.setFeedCacheEntries(this.feedResponseCache.size);
    }
    for (const [siteId, keys] of this.feedCacheSiteIndex.entries()) {
      keys.delete(cacheKey);
      if (keys.size === 0) this.feedCacheSiteIndex.delete(siteId);
    }
  }
}
