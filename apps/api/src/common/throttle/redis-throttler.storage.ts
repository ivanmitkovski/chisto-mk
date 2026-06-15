import { Injectable, OnModuleDestroy, Logger } from '@nestjs/common';
import { ThrottlerStorage } from '@nestjs/throttler';
import Redis from 'ioredis';

type RecordEntry = { totalHits: number; timeToExpire: number; isBlocked: boolean; timeToBlockExpire: number };

@Injectable()
export class RedisThrottlerStorage implements ThrottlerStorage, OnModuleDestroy {
  private readonly logger = new Logger(RedisThrottlerStorage.name);
  private redis: Redis | null;

  constructor() {
    const url = process.env.REDIS_URL?.trim();
    this.redis = url ? new Redis(url, { maxRetriesPerRequest: 1, lazyConnect: true }) : null;
    if (this.redis) {
      void this.redis.connect().catch(() => {
        // Fall back to in-memory behavior via thrown errors handled by guard
      });
    }
  }

  async increment(
    key: string,
    ttl: number,
    limit: number,
    blockDuration: number,
    throttlerName: string,
  ): Promise<RecordEntry> {
    if (!this.redis) {
      return this.unavailableRecord(ttl, limit, blockDuration, throttlerName, key);
    }
    const namespaced = `throttle:${throttlerName}:${key}`;
    try {
      const hits = await this.redis.incr(namespaced);
      if (hits === 1) {
        await this.redis.pexpire(namespaced, ttl);
      }
      const timeToExpire = await this.redis.pttl(namespaced);
      const isBlocked = hits > limit;
      return {
        totalHits: hits,
        timeToExpire: Math.max(0, timeToExpire),
        isBlocked,
        timeToBlockExpire: isBlocked ? blockDuration : 0,
      };
    } catch (err) {
      const nodeEnv = (process.env.NODE_ENV ?? 'development').trim().toLowerCase();
      const failClosed = nodeEnv === 'production' || nodeEnv === 'staging';
      if (failClosed) {
        this.logger.error({
          msg: 'throttle_redis_error_fail_closed',
          throttlerName,
          key,
          error: err instanceof Error ? err.message : String(err),
        });
        return {
          totalHits: limit + 1,
          timeToExpire: ttl,
          isBlocked: true,
          timeToBlockExpire: blockDuration,
        };
      }
      this.logger.warn({
        msg: 'throttle_redis_error_fallback',
        throttlerName,
        key,
        error: err instanceof Error ? err.message : String(err),
      });
      return this.unavailableRecord(ttl, limit, blockDuration, throttlerName, key);
    }
  }

  async onModuleDestroy(): Promise<void> {
    if (!this.redis) return;
    const client = this.redis;
    this.redis = null;
    await client.quit().catch(() => undefined);
  }

  private unavailableRecord(
    ttl: number,
    limit: number,
    blockDuration: number,
    throttlerName: string,
    key: string,
  ): RecordEntry {
    const nodeEnv = (process.env.NODE_ENV ?? 'development').trim().toLowerCase();
    const failClosed = nodeEnv === 'production' || nodeEnv === 'staging';
    if (failClosed) {
      this.logger.error({
        msg: 'throttle_redis_unavailable_fail_closed',
        throttlerName,
        key,
      });
      return {
        totalHits: limit + 1,
        timeToExpire: ttl,
        isBlocked: true,
        timeToBlockExpire: blockDuration,
      };
    }
    return { totalHits: 1, timeToExpire: ttl, isBlocked: false, timeToBlockExpire: 0 };
  }
}
