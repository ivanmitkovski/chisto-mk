import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import {
  PRESENCE_CONFIG,
  PRESENCE_REDIS_KEYS,
  presenceMetaKey,
} from '../config/presence.config';
import type { PresenceMeta } from '../types/presence.types';

type MemoryEntry = PresenceMeta & { expiresAt: number };

/**
 * Presence persistence: Redis (zset of members scored by expiry + per-member
 * meta keys with PX TTL) or an in-memory fallback when REDIS_URL is unset.
 */
@Injectable()
export class PresenceStoreService implements OnModuleDestroy {
  private readonly logger = new Logger(PresenceStoreService.name);
  private readonly redisUrl = process.env.REDIS_URL?.trim() || null;
  private readonly redis: Redis | null;
  private readonly memory = new Map<string, MemoryEntry>();

  constructor() {
    this.redis = this.redisUrl
      ? new Redis(this.redisUrl, { maxRetriesPerRequest: 1, lazyConnect: true })
      : null;
    if (!this.redisUrl) {
      this.logger.log('Active users presence using in-memory store (REDIS_URL unset)');
    }
  }

  onModuleDestroy(): void {
    void this.redis?.quit();
  }

  async upsert(member: string, meta: PresenceMeta, nowMs: number): Promise<void> {
    const expiresAt = nowMs + PRESENCE_CONFIG.ttlMs;
    if (this.redis) {
      await this.redis
        .multi()
        .zadd(PRESENCE_REDIS_KEYS.zset, expiresAt, member)
        .set(presenceMetaKey(member), JSON.stringify(meta), 'PX', PRESENCE_CONFIG.ttlMs)
        .zremrangebyscore(PRESENCE_REDIS_KEYS.zset, '-inf', nowMs)
        .exec();
      return;
    }
    this.memory.set(member, { ...meta, expiresAt });
    this.pruneMemory(nowMs);
  }

  async remove(member: string): Promise<void> {
    if (this.redis) {
      await this.redis
        .multi()
        .zrem(PRESENCE_REDIS_KEYS.zset, member)
        .del(presenceMetaKey(member))
        .exec();
      return;
    }
    this.memory.delete(member);
  }

  /** Overwrites meta for an existing member without bumping zset expiry. */
  async setMeta(member: string, meta: PresenceMeta): Promise<void> {
    if (this.redis) {
      await this.redis.set(
        presenceMetaKey(member),
        JSON.stringify(meta),
        'PX',
        PRESENCE_CONFIG.ttlMs,
      );
      return;
    }
    const entry = this.memory.get(member);
    if (entry) this.memory.set(member, { ...entry, ...meta });
  }

  async getMeta(member: string): Promise<PresenceMeta | null> {
    if (this.redis) {
      const raw = await this.redis.get(presenceMetaKey(member));
      if (!raw) return null;
      try {
        return JSON.parse(raw) as PresenceMeta;
      } catch {
        return null;
      }
    }
    const entry = this.memory.get(member);
    if (!entry || entry.expiresAt <= Date.now()) return null;
    const { expiresAt: _e, ...meta } = entry;
    return meta;
  }

  async listActiveMeta(): Promise<PresenceMeta[]> {
    const now = Date.now();
    if (this.redis) {
      await this.redis.zremrangebyscore(PRESENCE_REDIS_KEYS.zset, '-inf', now);
      const members = await this.redis.zrangebyscore(PRESENCE_REDIS_KEYS.zset, now, '+inf');
      if (members.length === 0) return [];
      const pipeline = this.redis.pipeline();
      for (const m of members) pipeline.get(presenceMetaKey(m));
      const results = await pipeline.exec();
      const metas: PresenceMeta[] = [];
      for (let i = 0; i < members.length; i += 1) {
        const raw = results?.[i]?.[1];
        if (typeof raw !== 'string') continue;
        try {
          metas.push(JSON.parse(raw) as PresenceMeta);
        } catch {
          /* skip */
        }
      }
      return metas;
    }
    this.pruneMemory(now);
    return [...this.memory.values()].map(({ expiresAt: _e, ...meta }) => meta);
  }

  private pruneMemory(now: number): void {
    for (const [key, entry] of this.memory) {
      if (entry.expiresAt <= now) this.memory.delete(key);
    }
  }
}
