import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import { Observable, Subject } from 'rxjs';
import { SiteEvent } from './site-events.types';

@Injectable()
export class SiteEventPublisherService implements OnModuleDestroy {
  private static readonly REDIS_CHANNEL = 'site-events';
  private static readonly REPLAY_LIMIT = 240;

  private readonly logger = new Logger(SiteEventPublisherService.name);
  private readonly events$ = new Subject<SiteEvent>();
  private readonly replayBuffer: SiteEvent[] = [];
  private readonly redisUrl = process.env.REDIS_URL?.trim() || null;
  private publisher: Redis | null = null;
  private subscriber: Redis | null = null;
  private redisEnabled = false;
  private subscriberReconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private subscriberReconnectAttempt = 0;
  private shuttingDown = false;

  constructor() {
    this.initRedis();
  }

  getEvents(): Observable<SiteEvent> {
    return this.events$.asObservable();
  }

  getReplaySinceMemory(lastEventId?: string): SiteEvent[] {
    const normalized = lastEventId?.trim();
    if (!normalized) return [];
    const index = this.replayBuffer.findIndex((event) => event.eventId === normalized);
    if (index < 0) return [];
    return this.replayBuffer.slice(index + 1);
  }

  publish(event: SiteEvent): void {
    this.publishLocal(event);
    if (!this.redisEnabled || !this.publisher) return;
    void this.publisher.publish(SiteEventPublisherService.REDIS_CHANNEL, JSON.stringify(event)).catch((error) => {
      this.logger.warn(`Redis publish failed (local SSE already emitted): ${String(error)}`);
    });
  }

  private publishLocal(event: SiteEvent): void {
    this.replayBuffer.push(event);
    while (this.replayBuffer.length > SiteEventPublisherService.REPLAY_LIMIT) {
      this.replayBuffer.shift();
    }
    queueMicrotask(() => this.events$.next(event));
  }

  private initRedis(): void {
    if (!this.redisUrl) return;
    try {
      this.publisher = new Redis(this.redisUrl);
      this.subscriber = new Redis(this.redisUrl);
      this.publisher.on('error', (error) => this.logger.warn(`Site events Redis publisher error: ${String(error)}`));
      this.subscriber.on('error', (error) =>
        this.logger.warn(`Site events Redis subscriber error: ${String(error)}`),
      );
      this.subscriber.on('message', (_channel, payload) => {
        try {
          const parsed = JSON.parse(payload) as SiteEvent;
          if (!parsed?.eventId || !parsed?.siteId || !parsed?.type) return;
          if (this.replayBuffer.some((e) => e.eventId === parsed.eventId)) return;
          this.publishLocal(parsed);
        } catch (error) {
          this.logger.warn(`Ignoring malformed site event payload from Redis: ${String(error)}`);
        }
      });
      void this.subscriber
        .subscribe(SiteEventPublisherService.REDIS_CHANNEL)
        .then(() => {
          this.redisEnabled = true;
          this.subscriberReconnectAttempt = 0;
          this.logger.log('Site events Redis fanout enabled');
        })
        .catch((error) => {
          this.logger.warn(`Site events Redis subscription failed: ${String(error)}`);
          this.redisEnabled = false;
          this.scheduleSubscriberResubscribe('initial subscribe failed');
        });
    } catch (error) {
      this.logger.warn(`Site events Redis initialization failed: ${String(error)}`);
      this.redisEnabled = false;
      this.publisher = null;
      this.subscriber = null;
    }
  }

  private scheduleSubscriberResubscribe(reason: string): void {
    if (this.shuttingDown || !this.redisUrl || this.subscriberReconnectTimer != null) return;
    this.redisEnabled = false;
    this.subscriberReconnectAttempt += 1;
    const attempt = Math.min(this.subscriberReconnectAttempt, 8);
    const baseMs = Math.min(30_000, 500 * 2 ** (attempt - 1));
    const jitterMs = Math.floor(Math.random() * 400);
    const delayMs = baseMs + jitterMs;
    this.logger.warn(
      `Site events Redis subscriber will retry in ${delayMs}ms (${reason}, attempt ${this.subscriberReconnectAttempt})`,
    );
    this.subscriberReconnectTimer = setTimeout(() => {
      this.subscriberReconnectTimer = null;
      void this.tryResubscribeSubscriber();
    }, delayMs);
  }

  private async tryResubscribeSubscriber(): Promise<void> {
    if (!this.subscriber || !this.redisUrl) return;
    try {
      await this.subscriber.subscribe(SiteEventPublisherService.REDIS_CHANNEL);
      this.redisEnabled = true;
      this.subscriberReconnectAttempt = 0;
      this.logger.log('Site events Redis fanout re-enabled after reconnect');
    } catch (error) {
      this.logger.warn(`Site events Redis resubscribe failed: ${String(error)}`);
      this.scheduleSubscriberResubscribe('resubscribe failed');
    }
  }

  async onModuleDestroy(): Promise<void> {
    this.shuttingDown = true;
    this.redisEnabled = false;
    if (this.subscriberReconnectTimer != null) {
      clearTimeout(this.subscriberReconnectTimer);
      this.subscriberReconnectTimer = null;
    }
    await Promise.allSettled([
      this.publisher?.quit() ?? Promise.resolve('publisher:closed'),
      this.subscriber?.quit() ?? Promise.resolve('subscriber:closed'),
    ]);
  }
}
