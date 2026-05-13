import { Injectable, Logger, OnModuleDestroy, OnModuleInit, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisFeedStateAdapter implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisFeedStateAdapter.name);
  private keyPrefix = 'chisto:dev:feed:';
  private client: Redis | null = null;
  private readonly memoryFallback = new Map<string, { value: string; expiresAt: number }>();

  constructor(@Optional() private readonly config: ConfigService | null) {}

  onModuleInit(): void {
    const cfg = (key: string): string | undefined =>
      this.config?.get<string>(key)?.trim() ?? process.env[key]?.trim();
    const env = cfg('ENV') ?? cfg('NODE_ENV') ?? 'dev';
    this.keyPrefix = `chisto:${env}:feed:`;
    const redisUrl = cfg('REDIS_URL');
    if (!redisUrl) {
      this.client = null;
      return;
    }
    this.client = new Redis(redisUrl, {
      maxRetriesPerRequest: 3,
      lazyConnect: false,
    });
    this.client.on('error', (err) => {
      this.logger.warn(`Feed Redis adapter error: ${String(err)}`);
    });
  }

  async onModuleDestroy(): Promise<void> {
    await this.client?.quit().catch(() => undefined);
  }

  async getJson<T>(key: string): Promise<T | null> {
    const redisKey = this.prefixed(key);
    if (!this.client) {
      const hit = this.memoryFallback.get(redisKey);
      if (!hit || hit.expiresAt < Date.now()) return null;
      return JSON.parse(hit.value) as T;
    }
    const raw = await this.client.get(redisKey);
    if (!raw) return null;
    return JSON.parse(raw) as T;
  }

  async setJson(key: string, value: unknown, ttlSec: number): Promise<void> {
    const redisKey = this.prefixed(key);
    const raw = JSON.stringify(value);
    if (!this.client) {
      this.memoryFallback.set(redisKey, {
        value: raw,
        expiresAt: Date.now() + ttlSec * 1000,
      });
      return;
    }
    await this.client.set(redisKey, raw, 'EX', ttlSec);
  }

  async zAddSeen(key: string, siteId: string, seenAtMs: number, ttlSec: number): Promise<void> {
    const redisKey = this.prefixed(key);
    if (!this.client) return;
    await this.client.multi().zadd(redisKey, seenAtMs, siteId).expire(redisKey, ttlSec).exec();
  }

  async zRangeSeen(key: string, minMs: number): Promise<Map<string, number>> {
    const redisKey = this.prefixed(key);
    if (!this.client) return new Map();
    const pairs = await this.client.zrangebyscore(redisKey, minMs, '+inf', 'WITHSCORES');
    const out = new Map<string, number>();
    for (let i = 0; i < pairs.length; i += 2) {
      const siteId = pairs[i];
      const score = Number(pairs[i + 1]);
      if (siteId && Number.isFinite(score)) out.set(siteId, score);
    }
    return out;
  }

  private prefixed(key: string): string {
    return `${this.keyPrefix}${key}`;
  }
}
