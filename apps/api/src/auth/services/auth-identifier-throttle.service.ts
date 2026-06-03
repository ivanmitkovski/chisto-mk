import { HttpException, HttpStatus, Injectable, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';

/** Per-identifier rate limits (phone/email) independent of client IP. */
@Injectable()
export class AuthIdentifierThrottleService implements OnModuleDestroy {
  private readonly redis: Redis | null;
  private readonly memory = new Map<string, { count: number; resetAt: number }>();

  constructor() {
    const url = process.env.REDIS_URL?.trim();
    this.redis = url ? new Redis(url, { maxRetriesPerRequest: 1, lazyConnect: true }) : null;
    if (this.redis) {
      void this.redis.connect().catch(() => undefined);
    }
  }

  async assertAllowed(scope: string, identifier: string, limit: number, windowSec: number): Promise<void> {
    const key = `${scope}:${identifier.trim().toLowerCase()}`;
    const count = await this.increment(key, windowSec);
    if (count > limit) {
      throw new HttpException(
        {
          code: 'RATE_LIMITED',
          message: 'Too many attempts for this identifier. Try again later.',
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private async increment(key: string, windowSec: number): Promise<number> {
    if (this.redis) {
      try {
        const namespaced = `auth-idem:${key}`;
        const count = await this.redis.incr(namespaced);
        if (count === 1) {
          await this.redis.expire(namespaced, windowSec);
        }
        return count;
      } catch {
        // fall through
      }
    }
    const now = Date.now();
    const row = this.memory.get(key);
    if (!row || row.resetAt < now) {
      this.memory.set(key, { count: 1, resetAt: now + windowSec * 1000 });
      return 1;
    }
    row.count += 1;
    return row.count;
  }

  onModuleDestroy(): void {
    this.redis?.disconnect();
  }
}
