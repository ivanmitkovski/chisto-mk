import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { createHash } from 'crypto';
import Redis from 'ioredis';
import type { AuthResponse } from '../types/auth-response.type';

type CacheEntry = {
  response: AuthResponse;
  expiresAtMs: number;
};

@Injectable()
export class AuthRefreshReplayCacheService implements OnModuleDestroy, OnModuleInit {
  private readonly logger = new Logger(AuthRefreshReplayCacheService.name);
  private readonly memory = new Map<string, CacheEntry>();
  private readonly redis: Redis | null;

  constructor() {
    const url = process.env.REDIS_URL?.trim();
    this.redis = url ? new Redis(url, { maxRetriesPerRequest: 1, lazyConnect: true }) : null;
    if (this.redis) {
      void this.redis.connect().catch(() => undefined);
    }
  }

  onModuleInit(): void {
    if (this.redis) return;
    const nodeEnv = process.env.NODE_ENV?.trim().toLowerCase();
    const warnMultiTask =
      nodeEnv === 'production' ||
      nodeEnv === 'staging' ||
      nodeEnv === 'development';
    if (warnMultiTask) {
      this.logger.error(
        'REDIS_URL is not configured; refresh-token rotation replay cache is in-memory only. ' +
          'Concurrent refresh across multiple API tasks returns INVALID_REFRESH_TOKEN and may log mobile users out. ' +
          'Configure ElastiCache REDIS_URL before running desiredCount >= 2. See docs/runbooks/redis-realtime.md.',
      );
    }
  }

  async get(previousTokenHash: string): Promise<AuthResponse | null> {
    const key = this.key(previousTokenHash);
    const local = this.memory.get(key);
    if (local) {
      if (Date.now() <= local.expiresAtMs) return local.response;
      this.memory.delete(key);
    }

    if (!this.redis) return null;
    try {
      const payload = await this.redis.get(key);
      return payload ? (JSON.parse(payload) as AuthResponse) : null;
    } catch {
      return null;
    }
  }

  async set(previousTokenHash: string, response: AuthResponse, ttlSeconds: number): Promise<void> {
    if (ttlSeconds <= 0) return;
    const key = this.key(previousTokenHash);
    this.memory.set(key, {
      response,
      expiresAtMs: Date.now() + ttlSeconds * 1000,
    });
    if (!this.redis) return;
    try {
      await this.redis.set(key, JSON.stringify(response), 'EX', ttlSeconds);
    } catch {
      // In-memory replay still protects single-instance deployments.
    }
  }

  onModuleDestroy(): void {
    this.redis?.disconnect();
  }

  private key(previousTokenHash: string): string {
    return `auth:rotation:${createHash('sha256').update(previousTokenHash).digest('hex')}`;
  }
}
