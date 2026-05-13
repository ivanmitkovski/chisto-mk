import { Injectable } from '@nestjs/common';
import { ObservabilityStore } from '../observability/observability.store';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ListSitesQueryDto } from './dto/list-sites-query.dto';
import type { SitesFeedListResult } from './sites-feed.types';

@Injectable()
export class SitesFeedCacheService {
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
      query.cursor ?? '',
      query.explain ? 1 : 0,
    ].join('|');
  }

  get(key: string):
    | {
        cachedAt: number;
        value: SitesFeedListResult;
      }
    | undefined {
    return this.feedResponseCache.get(key);
  }

  set(key: string, value: SitesFeedListResult, siteIds: string[], nowMs: number): void {
    this.feedResponseCache.set(key, { cachedAt: nowMs, value });
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
      for (const row of cached.value.data) {
        const keys = this.feedCacheSiteIndex.get(row.id);
        if (!keys) continue;
        keys.delete(cacheKey);
        if (keys.size === 0) this.feedCacheSiteIndex.delete(row.id);
      }
    }
    this.feedResponseCache.delete(cacheKey);
    ObservabilityStore.setFeedCacheEntries(this.feedResponseCache.size);
  }
}
