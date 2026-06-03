import { Injectable, OnModuleDestroy, UnauthorizedException } from '@nestjs/common';
import Redis from 'ioredis';
import { isDeployedNodeEnv } from '../../common/env/deploy-env.util';

const REPLAY_WINDOW_MS = 5 * 60 * 1000;

@Injectable()
export class TwilioWebhookDedupeService implements OnModuleDestroy {
  private readonly redis: Redis | null;
  private readonly memory = new Map<string, number>();

  constructor() {
    const url = process.env.REDIS_URL?.trim();
    this.redis = url ? new Redis(url, { maxRetriesPerRequest: 1, lazyConnect: true }) : null;
    if (this.redis) {
      void this.redis.connect().catch(() => undefined);
    }
  }

  /** Reject duplicate MessageSid within replay window; reject stale callbacks (>5 min). */
  async assertFresh(messageSid: string, eventTime?: string): Promise<void> {
    const sid = messageSid.trim();
    if (!sid) {
      throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Invalid request' });
    }
    if (eventTime) {
      const ts = Date.parse(eventTime);
      if (Number.isFinite(ts) && Date.now() - ts > REPLAY_WINDOW_MS) {
        throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Invalid request' });
      }
    }
    const isNew = await this.markOnce(`twilio:${sid}`, REPLAY_WINDOW_MS);
    if (!isNew) {
      throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Invalid request' });
    }
  }

  private async markOnce(key: string, ttlMs: number): Promise<boolean> {
    if (this.redis) {
      try {
        const result = await this.redis.set(key, '1', 'PX', ttlMs, 'NX');
        return result === 'OK';
      } catch {
        if (isDeployedNodeEnv()) {
          throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Invalid request' });
        }
      }
    }
    if (isDeployedNodeEnv()) {
      throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Invalid request' });
    }
    const expires = this.memory.get(key);
    if (expires && expires > Date.now()) {
      return false;
    }
    this.memory.set(key, Date.now() + ttlMs);
    return true;
  }

  onModuleDestroy(): void {
    this.redis?.disconnect();
  }
}
