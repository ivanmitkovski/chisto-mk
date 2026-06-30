import { Injectable, OnModuleDestroy, ServiceUnavailableException } from '@nestjs/common';
import Redis from 'ioredis';
import { isDeployedNodeEnv } from '../env/deploy-env.util';

export type StoredIdempotentResponse = {
  statusCode: number;
  body: unknown;
};

@Injectable()
export class IdempotencyResponseStore implements OnModuleDestroy {
  private readonly redis: Redis | null;
  private readonly memory = new Map<string, { expiresAt: number; value: StoredIdempotentResponse }>();

  constructor() {
    const url = process.env.REDIS_URL?.trim();
    this.redis = url ? new Redis(url, { maxRetriesPerRequest: 1, lazyConnect: true }) : null;
    if (this.redis) {
      void this.redis.connect().catch(() => undefined);
    }
  }

  async get(key: string): Promise<StoredIdempotentResponse | null> {
    if (this.redis) {
      try {
        const raw = await this.redis.get(`idem:${key}`);
        if (!raw) return null;
        return JSON.parse(raw) as StoredIdempotentResponse;
      } catch {
        if (isDeployedNodeEnv()) {
          throw new ServiceUnavailableException({
            code: 'IDEMPOTENCY_STORE_UNAVAILABLE',
            message: 'Idempotency store is temporarily unavailable',
          });
        }
        return null;
      }
    }
    if (isDeployedNodeEnv()) {
      throw new ServiceUnavailableException({
        code: 'IDEMPOTENCY_STORE_UNAVAILABLE',
        message: 'Idempotency store requires Redis in production',
      });
    }
    const row = this.memory.get(key);
    if (!row || row.expiresAt < Date.now()) {
      this.memory.delete(key);
      return null;
    }
    return row.value;
  }

  async tryAcquireInFlightLock(lockKey: string, ttlMs: number): Promise<boolean> {
    if (this.redis) {
      try {
        const ok = await this.redis.set(`idem:lock:${lockKey}`, '1', 'PX', ttlMs, 'NX');
        return ok === 'OK';
      } catch {
        if (isDeployedNodeEnv()) {
          throw new ServiceUnavailableException({
            code: 'IDEMPOTENCY_STORE_UNAVAILABLE',
            message: 'Idempotency store is temporarily unavailable',
          });
        }
        return true;
      }
    }
    if (isDeployedNodeEnv()) {
      throw new ServiceUnavailableException({
        code: 'IDEMPOTENCY_STORE_UNAVAILABLE',
        message: 'Idempotency store requires Redis in production',
      });
    }
    return true;
  }

  async releaseInFlightLock(lockKey: string): Promise<void> {
    if (!this.redis) return;
    try {
      await this.redis.del(`idem:lock:${lockKey}`);
    } catch {
      // best-effort
    }
  }

  async set(key: string, value: StoredIdempotentResponse, ttlMs: number): Promise<void> {
    if (this.redis) {
      try {
        await this.redis.set(`idem:${key}`, JSON.stringify(value), 'PX', ttlMs);
        return;
      } catch {
        if (isDeployedNodeEnv()) {
          throw new ServiceUnavailableException({
            code: 'IDEMPOTENCY_STORE_UNAVAILABLE',
            message: 'Idempotency store is temporarily unavailable',
          });
        }
      }
    }
    if (isDeployedNodeEnv()) {
      throw new ServiceUnavailableException({
        code: 'IDEMPOTENCY_STORE_UNAVAILABLE',
        message: 'Idempotency store requires Redis in production',
      });
    }
    this.memory.set(key, { value, expiresAt: Date.now() + ttlMs });
  }

  onModuleDestroy(): void {
    this.redis?.disconnect();
  }
}
