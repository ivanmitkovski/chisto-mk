import { Injectable, Logger } from '@nestjs/common';
import Redis from 'ioredis';
import { loadMapConfig } from '../../config/map.config';
import { ObservabilityStore } from '../../observability/observability.store';
import { MapResponse } from './map-types';

@Injectable()
export class MapCacheService {
  private static readonly REDIS_KEY_PREFIX = 'sites:map:v2';
  private static readonly REDIS_INDEX_KEY = 'sites:map:v2:index';
  private static readonly cfg = loadMapConfig();
  private readonly mapCacheTtlMs = MapCacheService.cfg.cacheTtlMs;
  private readonly memoryCache = new Map<string, { cachedAt: number; value: MapResponse }>();
  private readonly memorySiteIndex = new Map<string, Set<string>>();
  private readonly redis: Redis | null;
  private readonly logger = new Logger(MapCacheService.name);

  constructor() {
    this.redis = MapCacheService.cfg.redisUrl
      ? new Redis(MapCacheService.cfg.redisUrl, { lazyConnect: true })
      : null;
  }

  getTtlMs(): number {
    return this.mapCacheTtlMs;
  }

  buildCacheKey(parts: Array<string | number | null | undefined>): string {
    return parts.map((part) => (part == null ? '' : String(part))).join('|');
  }

  getFromMemory(cacheKey: string): MapResponse | null {
    const now = Date.now();
    const cached = this.memoryCache.get(cacheKey);
    if (!cached) return null;
    if (now - cached.cachedAt > this.mapCacheTtlMs) return null;
    // Approximate LRU: move accessed key to map tail.
    this.memoryCache.delete(cacheKey);
    this.memoryCache.set(cacheKey, cached);
    return cached.value;
  }

  async getFromRedis(cacheKey: string): Promise<MapResponse | null> {
    if (!this.redis) return null;
    try {
      await this.redis.connect().catch(() => undefined);
      const raw = await this.redis.get(this.redisKey(cacheKey));
      if (!raw) return null;
      return JSON.parse(raw) as MapResponse;
    } catch (error) {
      this.logger.warn(`redis map-cache read failed: ${String(error)}`);
      return null;
    }
  }

  async set(cacheKey: string, value: MapResponse): Promise<void> {
    this.memoryCache.set(cacheKey, { cachedAt: Date.now(), value });
    this.indexCacheKeySites(
      cacheKey,
      value.data.map((row: MapResponse['data'][number]) => row.id),
    );
    if (this.memoryCache.size > 300) {
      const oldestKey = this.memoryCache.keys().next().value as string | undefined;
      if (oldestKey) this.removeMemoryKey(oldestKey);
    }
    ObservabilityStore.setMapCacheEntries(this.memoryCache.size);
    if (!this.redis) return;
    try {
      await this.redis.connect().catch(() => undefined);
      const redisKey = this.redisKey(cacheKey);
      await this.redis.set(redisKey, JSON.stringify(value), 'PX', this.mapCacheTtlMs);
      await this.redis.sadd(MapCacheService.REDIS_INDEX_KEY, redisKey);
      await this.redis.pexpire(MapCacheService.REDIS_INDEX_KEY, this.mapCacheTtlMs);
    } catch (error) {
      this.logger.warn(`redis map-cache write failed: ${String(error)}`);
      return;
    }
  }

  async invalidate(reason: string, siteId?: string): Promise<void> {
    ObservabilityStore.recordMapCacheInvalidation(reason);
    if (siteId) {
      const keys = this.memorySiteIndex.get(siteId);
      if (keys && keys.size > 0) {
        for (const key of [...keys]) {
          this.removeMemoryKey(key);
        }
        this.memorySiteIndex.delete(siteId);
      } else {
        // No known cache key for this site: targeted invalidation should be a no-op.
        ObservabilityStore.setMapCacheEntries(this.memoryCache.size);
        return;
      }
    } else {
      this.memoryCache.clear();
      this.memorySiteIndex.clear();
    }
    ObservabilityStore.setMapCacheEntries(this.memoryCache.size);
    if (!this.redis) return;
    try {
      await this.redis.connect().catch(() => undefined);
      let cursor = '0';
      do {
        const [nextCursor, keys] = await this.redis.scan(cursor, 'MATCH', this.redisKey('*'), 'COUNT', 200);
        cursor = nextCursor;
        if (keys.length > 0) {
          await this.redis.del(...keys);
        }
      } while (cursor !== '0');
      const indexedKeys = await this.redis.smembers(MapCacheService.REDIS_INDEX_KEY);
      if (indexedKeys.length > 0) {
        await this.redis.del(...indexedKeys);
      }
      await this.redis.del(MapCacheService.REDIS_INDEX_KEY);
    } catch (error) {
      this.logger.warn(`redis map-cache invalidate failed: ${String(error)}`);
      return;
    }
  }

  private redisKey(cacheKey: string): string {
    return `${MapCacheService.REDIS_KEY_PREFIX}:${cacheKey}`;
  }

  private indexCacheKeySites(cacheKey: string, siteIds: string[]): void {
    for (const siteId of siteIds) {
      const set = this.memorySiteIndex.get(siteId) ?? new Set<string>();
      set.add(cacheKey);
      this.memorySiteIndex.set(siteId, set);
    }
  }

  private removeMemoryKey(cacheKey: string): void {
    const cached = this.memoryCache.get(cacheKey);
    if (cached) {
      for (const row of cached.value.data) {
        const keys = this.memorySiteIndex.get(row.id);
        if (!keys) continue;
        keys.delete(cacheKey);
        if (keys.size === 0) this.memorySiteIndex.delete(row.id);
      }
    }
    this.memoryCache.delete(cacheKey);
  }
}
