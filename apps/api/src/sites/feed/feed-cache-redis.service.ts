import { Injectable, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';

const TTL_SEC = 15;

@Injectable()
export class FeedCacheRedisService implements OnModuleDestroy {
  private readonly redis: Redis | null;

  constructor() {
    const url = process.env.REDIS_URL?.trim();
    this.redis = url ? new Redis(url, { maxRetriesPerRequest: 1, lazyConnect: true }) : null;
    if (this.redis) {
      void this.redis.connect().catch(() => undefined);
    }
  }

  async get(key: string): Promise<string | null> {
    if (!this.redis) return null;
    try {
      return await this.redis.get(`feed:${key}`);
    } catch {
      return null;
    }
  }

  async set(key: string, payload: string): Promise<void> {
    if (!this.redis) return;
    try {
      await this.redis.set(`feed:${key}`, payload, 'EX', TTL_SEC);
    } catch {
      // L1 cache remains authoritative when Redis is down
    }
  }

  async invalidateTag(tag: string): Promise<void> {
    if (!this.redis) return;
    try {
      const keys = await this.redis.keys(`feed:*${tag}*`);
      if (keys.length > 0) await this.redis.del(...keys);
    } catch {
      // best-effort
    }
  }

  onModuleDestroy(): void {
    this.redis?.disconnect();
  }
}
