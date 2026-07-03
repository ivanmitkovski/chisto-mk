import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import { optionalLazyRedisOptions } from '../../common/redis/optional-lazy-redis-options';
import { Observable, Subject } from 'rxjs';
import {
  PRESENCE_REDIS_KEYS,
} from '../config/presence.config';
import type {
  ActiveUsersUpdatedEvent,
  ActivityEventRealtime,
  AlertTriggeredEvent,
} from '../types/presence.types';

export type ActiveUsersRealtimeEvent =
  | ActiveUsersUpdatedEvent
  | ActivityEventRealtime
  | AlertTriggeredEvent;

@Injectable()
export class ActiveUsersRealtimeService implements OnModuleDestroy {
  private static readonly REDIS_CHANNEL = 'active-users-events';

  private readonly logger = new Logger(ActiveUsersRealtimeService.name);
  private readonly events$ = new Subject<ActiveUsersRealtimeEvent>();
  private readonly redisUrl = process.env.REDIS_URL?.trim() || null;
  private publisher: Redis | null = null;
  private subscriber: Redis | null = null;
  private trendSamples: Array<{ at: number; count: number }> = [];
  private avgSampleSum = 0;
  private avgSampleCount = 0;

  constructor() {
    if (this.redisUrl) {
      this.publisher = new Redis(this.redisUrl, optionalLazyRedisOptions);
      this.subscriber = new Redis(this.redisUrl, optionalLazyRedisOptions);
      void this.subscriber
        .subscribe(ActiveUsersRealtimeService.REDIS_CHANNEL)
        .then(() => {
          this.subscriber!.on('message', (_ch, payload) => {
            try {
              const parsed = JSON.parse(payload) as ActiveUsersRealtimeEvent;
              if (parsed?.type) this.events$.next(parsed);
            } catch {
              /* ignore */
            }
          });
        })
        .catch((err) => this.logger.warn(`Active users Redis subscribe failed: ${String(err)}`));
    }
  }

  async onModuleDestroy(): Promise<void> {
    const publisher = this.publisher;
    const subscriber = this.subscriber;
    this.publisher = null;
    this.subscriber = null;
    await Promise.all([
      publisher?.quit().catch(() => undefined),
      subscriber?.quit().catch(() => undefined),
    ]);
  }

  getEvents(): Observable<ActiveUsersRealtimeEvent> {
    return this.events$.asObservable();
  }

  publishActiveUsersUpdated(event: ActiveUsersUpdatedEvent): void {
    this.emit(event);
  }

  publishActivityEvent(event: ActivityEventRealtime): void {
    this.emit(event);
  }

  publishAlertTriggered(event: AlertTriggeredEvent): void {
    this.emit(event);
  }

  private emit(event: ActiveUsersRealtimeEvent): void {
    queueMicrotask(() => this.events$.next(event));
    if (this.publisher) {
      void this.publisher
        .publish(ActiveUsersRealtimeService.REDIS_CHANNEL, JSON.stringify(event))
        .catch((err) => this.logger.warn(`Redis publish failed: ${String(err)}`));
    }
  }

  async recordConcurrentSample(count: number): Promise<void> {
    const now = Date.now();
    this.trendSamples.push({ at: now, count });
    const cutoff1h = now - 60 * 60 * 1000;
    this.trendSamples = this.trendSamples.filter((s) => s.at >= cutoff1h);

    this.avgSampleSum += count;
    this.avgSampleCount += 1;

    if (this.publisher) {
      try {
        const todayKey = this.todayKey();
        const weekKey = this.weekKey();
        const currentPeakToday = Number((await this.publisher.get(PRESENCE_REDIS_KEYS.peakToday)) ?? 0);
        const currentPeakWeek = Number((await this.publisher.get(PRESENCE_REDIS_KEYS.peakWeek)) ?? 0);
        if (count > currentPeakToday) {
          await this.publisher.set(PRESENCE_REDIS_KEYS.peakToday, String(count), 'EX', 86400);
        }
        if (count > currentPeakWeek) {
          await this.publisher.set(PRESENCE_REDIS_KEYS.peakWeek, String(count), 'EX', 7 * 86400);
        }
        const sampleMember = `${now}:${count}`;
        await this.publisher
          .multi()
          .zadd(PRESENCE_REDIS_KEYS.trendSamples, now, sampleMember)
          .zremrangebyscore(PRESENCE_REDIS_KEYS.trendSamples, '-inf', cutoff1h - 1)
          .expire(PRESENCE_REDIS_KEYS.trendSamples, 86400)
          .hincrby(PRESENCE_REDIS_KEYS.avgStats, 'sum', count)
          .hincrby(PRESENCE_REDIS_KEYS.avgStats, 'count', 1)
          .expire(PRESENCE_REDIS_KEYS.avgStats, 86400 * 2)
          .exec();
        await this.publisher.lpush(`${PRESENCE_REDIS_KEYS.trendPrefix}${todayKey}`, sampleMember);
        await this.publisher.ltrim(`${PRESENCE_REDIS_KEYS.trendPrefix}${todayKey}`, 0, 240);
        await this.publisher.expire(`${PRESENCE_REDIS_KEYS.trendPrefix}${todayKey}`, 86400);
        void weekKey;
      } catch (err) {
        this.logger.warn(
          `recordConcurrentSample failed: ${err instanceof Error ? err.message : String(err)}`,
        );
      }
    }
  }

  async recordDau(userId: string): Promise<void> {
    if (!this.publisher) return;
    try {
      const key = `${PRESENCE_REDIS_KEYS.dauPrefix}${this.todayKey()}`;
      await this.publisher.pfadd(key, userId);
      await this.publisher.expire(key, 86400 * 2);
      await this.publisher.pfadd(PRESENCE_REDIS_KEYS.wauKey, userId);
      await this.publisher.expire(PRESENCE_REDIS_KEYS.wauKey, 86400 * 8);
      await this.publisher.pfadd(PRESENCE_REDIS_KEYS.mauKey, userId);
      await this.publisher.expire(PRESENCE_REDIS_KEYS.mauKey, 86400 * 32);
    } catch (err) {
      this.logger.warn(`recordDau failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  }

  async getPeakToday(): Promise<number> {
    if (this.publisher) {
      return Number((await this.publisher.get(PRESENCE_REDIS_KEYS.peakToday)) ?? 0);
    }
    return Math.max(0, ...this.trendSamples.map((s) => s.count));
  }

  async getPeakWeek(): Promise<number> {
    if (this.publisher) {
      return Number((await this.publisher.get(PRESENCE_REDIS_KEYS.peakWeek)) ?? 0);
    }
    return Math.max(0, ...this.trendSamples.map((s) => s.count));
  }

  async getAvgConcurrent(): Promise<number> {
    if (this.publisher) {
      const [sumRaw, countRaw] = await this.publisher.hmget(
        PRESENCE_REDIS_KEYS.avgStats,
        'sum',
        'count',
      );
      const count = Number(countRaw ?? 0);
      if (count === 0) return 0;
      return Math.round((Number(sumRaw ?? 0) / count) * 10) / 10;
    }
    if (this.avgSampleCount === 0) return 0;
    return Math.round((this.avgSampleSum / this.avgSampleCount) * 10) / 10;
  }

  async getTrend(windowMs: number): Promise<number[]> {
    const now = Date.now();
    const cutoff = now - windowMs;
    if (this.publisher) {
      const members = await this.publisher.zrangebyscore(
        PRESENCE_REDIS_KEYS.trendSamples,
        cutoff,
        now,
      );
      return members
        .map((member) => Number(member.split(':')[1]))
        .filter((value) => !Number.isNaN(value));
    }
    return this.trendSamples.filter((s) => s.at >= cutoff).map((s) => s.count);
  }

  async getDauWauMau(): Promise<{ dau: number; wau: number; mau: number }> {
    if (!this.publisher) return { dau: 0, wau: 0, mau: 0 };
    const dauKey = `${PRESENCE_REDIS_KEYS.dauPrefix}${this.todayKey()}`;
    const [dau, wau, mau] = await Promise.all([
      this.publisher.pfcount(dauKey),
      this.publisher.pfcount(PRESENCE_REDIS_KEYS.wauKey),
      this.publisher.pfcount(PRESENCE_REDIS_KEYS.mauKey),
    ]);
    return { dau, wau, mau };
  }

  private todayKey(): string {
    return new Date().toISOString().slice(0, 10);
  }

  private weekKey(): string {
    const d = new Date();
    const onejan = new Date(d.getFullYear(), 0, 1);
    const week = Math.ceil(((d.getTime() - onejan.getTime()) / 86400000 + onejan.getDay() + 1) / 7);
    return `${d.getFullYear()}-W${week}`;
  }
}
