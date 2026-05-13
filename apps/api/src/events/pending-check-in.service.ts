import {
  Injectable,
  InternalServerErrorException,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
  Optional,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { randomUUID } from 'node:crypto';

export interface PendingCheckIn {
  pendingId: string;
  eventId: string;
  userId: string;
  firstName: string;
  lastName: string;
  /** Signed GET URL for private S3 avatar; null when user has no avatar. */
  avatarUrl?: string | null;
  createdAt: string;
  expiresAt: string;
}

const DEFAULT_TTL_SEC = 60;

function mustUseRedis(cfg: (key: string) => string | undefined): boolean {
  const nodeEnv = (cfg('NODE_ENV') ?? 'development').toLowerCase();
  const flag = cfg('CHECK_IN_REQUIRE_REDIS')?.toLowerCase();
  return nodeEnv === 'production' || flag === '1' || flag === 'true';
}

@Injectable()
export class PendingCheckInService implements OnModuleDestroy, OnModuleInit {
  private readonly logger = new Logger(PendingCheckInService.name);
  private cfg!: (key: string) => string | undefined;
  private ttlSec = DEFAULT_TTL_SEC;
  private keyPrefix = 'chisto:development:checkin:pending:';
  private requireRedis = false;
  private redis: Redis | null = null;

  constructor(@Optional() private readonly config: ConfigService | null) {}

  onModuleInit(): void {
    this.cfg = (key: string) =>
      this.config?.get<string>(key)?.trim() ?? process.env[key]?.trim();

    const envTtl = this.cfg('CHECK_IN_CONFIRM_TTL_SEC');
    this.ttlSec =
      envTtl != null ? Math.max(10, parseInt(envTtl, 10) || DEFAULT_TTL_SEC) : DEFAULT_TTL_SEC;

    const env = this.cfg('NODE_ENV') ?? 'development';
    this.keyPrefix = `chisto:${env}:checkin:pending:`;
    this.requireRedis = mustUseRedis(this.cfg);

    this.initRedis();

    if (this.requireRedis && this.redis == null) {
      const message =
        'Redis is required for pending check-in (NODE_ENV=production or CHECK_IN_REQUIRE_REDIS=true) but REDIS_URL is missing or Redis failed to initialize. Multi-instance check-in is unsafe without Redis.';
      this.logger.error(message);
      throw new InternalServerErrorException({
        code: 'CHECK_IN_REDIS_REQUIRED',
        message,
      });
    }
  }

  onModuleDestroy(): void {
    void this.redis?.quit().catch(() => undefined);
    this.redis = null;
  }

  get confirmTtlSec(): number {
    return this.ttlSec;
  }

  private initRedis(): void {
    const url = this.cfg('REDIS_URL');
    if (!url) {
      if (this.requireRedis) {
        this.logger.error(
          'REDIS_URL not set while Redis is required for pending check-in (production or CHECK_IN_REQUIRE_REDIS).',
        );
        return;
      }
      this.logger.warn(
        'REDIS_URL not set — PendingCheckInService will use in-memory fallback (single-instance only). Set CHECK_IN_REQUIRE_REDIS=true locally to fail fast like production.',
      );
      return;
    }
    try {
      const useTls =
        url.startsWith('rediss://') ||
        this.cfg('REDIS_TLS') === '1' ||
        this.cfg('REDIS_TLS')?.toLowerCase() === 'true';
      this.redis = new Redis(url, {
        ...(useTls ? { tls: { rejectUnauthorized: this.cfg('REDIS_TLS_REJECT_UNAUTHORIZED') !== '0' } } : {}),
        maxRetriesPerRequest: 3,
        lazyConnect: false,
      });
      this.redis.on('error', (err) => {
        this.logger.warn(`Redis connection error: ${String(err)}`);
      });
    } catch (err) {
      this.logger.error(`Failed to connect to Redis: ${String(err)}`);
    }
  }

  /** In-memory fallback for dev/test when Redis is unavailable. */
  private readonly memoryStore = new Map<string, { data: PendingCheckIn; expiresAtMs: number }>();

  async createPending(
    eventId: string,
    userId: string,
    firstName: string,
    lastName: string,
    avatarUrl: string | null,
  ): Promise<PendingCheckIn> {
    const pendingId = randomUUID();
    const now = new Date();
    const expiresAt = new Date(now.getTime() + this.ttlSec * 1000);
    const pending: PendingCheckIn = {
      pendingId,
      eventId,
      userId,
      firstName,
      lastName,
      avatarUrl,
      createdAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
    };

    if (this.redis) {
      const key = `${this.keyPrefix}${pendingId}`;
      await this.redis.set(key, JSON.stringify(pending), 'EX', this.ttlSec);
    } else {
      this.memoryStore.set(pendingId, { data: pending, expiresAtMs: expiresAt.getTime() });
    }

    return pending;
  }

  async getPending(pendingId: string): Promise<PendingCheckIn | null> {
    if (this.redis) {
      const key = `${this.keyPrefix}${pendingId}`;
      const raw = await this.redis.get(key);
      if (raw == null) {
        return null;
      }
      try {
        const parsed = JSON.parse(raw) as PendingCheckIn;
        return { ...parsed, avatarUrl: parsed.avatarUrl ?? null };
      } catch {
        return null;
      }
    }

    const entry = this.memoryStore.get(pendingId);
    if (!entry) {
      return null;
    }
    if (Date.now() > entry.expiresAtMs) {
      this.memoryStore.delete(pendingId);
      return null;
    }
    return entry.data;
  }

  async deletePending(pendingId: string): Promise<void> {
    if (this.redis) {
      const key = `${this.keyPrefix}${pendingId}`;
      await this.redis.del(key);
    } else {
      this.memoryStore.delete(pendingId);
    }
  }
}
