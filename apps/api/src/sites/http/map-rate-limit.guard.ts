import {
  CanActivate,
  ExecutionContext,
  HttpException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import type { Request } from 'express';
import Redis from 'ioredis';
import { loadMapConfig } from '../../config/map.config';
import { MAP_RATE_LIMIT_INCR_SCRIPT } from './map-rate-limit-lua';

type MemoryCounter = { count: number; expiresAtMs: number };

@Injectable()
export class MapRateLimitGuard implements CanActivate {
  private static readonly cfg = loadMapConfig();
  private readonly logger = new Logger(MapRateLimitGuard.name);
  private readonly redis: Redis | null;
  private readonly ttlSeconds = 60;
  private readonly mapLimit: number;
  private readonly sseLimit: number;
  private readonly trustedProxyCidrs: string[];
  private readonly memoryCounters = new Map<string, MemoryCounter>();

  constructor() {
    const nodeEnv = (process.env.NODE_ENV ?? 'development').trim().toLowerCase();
    if (nodeEnv === 'production' && !MapRateLimitGuard.cfg.redisUrl?.trim()) {
      this.logger.error(
        'REDIS_URL is required in production for MapRateLimitGuard (horizontal rate limits). Exiting.',
      );
      process.exit(1);
    }
    this.redis = MapRateLimitGuard.cfg.redisUrl
      ? new Redis(MapRateLimitGuard.cfg.redisUrl, { lazyConnect: true })
      : null;
    this.trustedProxyCidrs = MapRateLimitGuard.cfg.trustedProxyCidrs;
    this.mapLimit = Math.max(120, MapRateLimitGuard.cfg.mapHttpRpsLimit);
    this.sseLimit = Math.max(40, MapRateLimitGuard.cfg.mapSseRpsLimit);
  }

  private _memoryIncrAndCheck(key: string, limit: number): void {
    const now = Date.now();
    const windowMs = this.ttlSeconds * 1000;
    const existing = this.memoryCounters.get(key);
    let next: MemoryCounter;
    if (!existing || existing.expiresAtMs <= now) {
      next = { count: 1, expiresAtMs: now + windowMs };
    } else {
      next = { count: existing.count + 1, expiresAtMs: existing.expiresAtMs };
    }
    this.memoryCounters.set(key, next);
    if (this.memoryCounters.size > 50_000) {
      for (const [k, v] of this.memoryCounters) {
        if (v.expiresAtMs <= now) {
          this.memoryCounters.delete(k);
        }
      }
    }
    if (next.count > limit) {
      throw new HttpException(
        {
          code: 'MAP_RATE_LIMITED',
          message: 'Too many map requests. Please retry later.',
          details: { ttlSeconds: this.ttlSeconds, limit, mode: 'memory' },
        },
        429,
      );
    }
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<Request>();
    const rawForwarded = (req.headers['x-forwarded-for'] as string | undefined)?.split(',')[0]?.trim();
    const proxyTrusted =
      this.trustedProxyCidrs.length > 0 && this.trustedProxyCidrs.includes(req.ip ?? '');
    const ip = proxyTrusted && rawForwarded ? rawForwarded : (req.ip ?? 'unknown');
    const accept = req.headers.accept ?? '';
    const route = req.route?.path ?? req.path;
    const isSse =
      (typeof accept === 'string' && accept.includes('text/event-stream')) ||
      (typeof route === 'string' && route.endsWith('/events'));
    const limit = isSse ? this.sseLimit : this.mapLimit;
    const deviceId =
      typeof req.headers['x-device-id'] === 'string'
        ? req.headers['x-device-id'].trim().slice(0, 64)
        : '';
    const key = `rl:map:${isSse ? 'sse' : 'http'}:${ip}${deviceId ? `:${deviceId}` : ''}`;

    if (!this.redis) {
      this._memoryIncrAndCheck(key, limit);
      return true;
    }

    const nodeEnv = (process.env.NODE_ENV ?? 'development').trim().toLowerCase();
    try {
      await this.redis.connect().catch(() => undefined);
      const countRaw = await this.redis.eval(
        MAP_RATE_LIMIT_INCR_SCRIPT,
        1,
        key,
        String(this.ttlSeconds),
      );
      const count = typeof countRaw === 'number' ? countRaw : Number(countRaw);
      if (count > limit) {
        throw new HttpException(
          {
            code: 'MAP_RATE_LIMITED',
            message: 'Too many map requests. Please retry later.',
            details: { ttlSeconds: this.ttlSeconds, limit, mode: 'redis' },
          },
          429,
        );
      }
      return true;
    } catch (err) {
      if (err instanceof HttpException) {
        throw err;
      }
      if (nodeEnv === 'production') {
        this.logger.error(
          `Redis map rate limit backend error (${err instanceof Error ? err.message : String(err)})`,
        );
        throw new ServiceUnavailableException({
          code: 'MAP_RATE_LIMIT_BACKEND',
          message: 'Map rate limit service temporarily unavailable.',
        });
      }
      this.logger.warn(
        `Redis map rate limit error (${err instanceof Error ? err.message : String(err)}) — using in-memory fallback`,
      );
      this._memoryIncrAndCheck(key, limit);
      return true;
    }
  }
}
