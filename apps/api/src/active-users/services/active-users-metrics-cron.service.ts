import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import Redis from 'ioredis';
import { PrismaService } from '../../prisma/prisma.service';
import { PRESENCE_CONFIG } from '../config/presence.config';
import { ActiveUsersPresenceService } from './active-users-presence.service';
import { ActiveUsersRealtimeService } from './active-users-realtime.service';

@Injectable()
export class ActiveUsersMetricsCronService implements OnModuleInit, OnModuleDestroy {
  private static readonly LEADER_LOCK_KEY = 'leader:active-users-metrics';
  private static readonly LEADER_LOCK_TTL_SECONDS = 30;

  private readonly logger = new Logger(ActiveUsersMetricsCronService.name);
  private readonly redisUrl = process.env.REDIS_URL?.trim() || null;
  private readonly redis = this.redisUrl ? new Redis(this.redisUrl, { lazyConnect: true }) : null;
  private samplerTimer: ReturnType<typeof setInterval> | null = null;
  private rollupTimer: ReturnType<typeof setInterval> | null = null;
  private leaderRenewTimer: ReturnType<typeof setInterval> | null = null;
  private readonly leaderToken = `${process.pid}:${Math.random().toString(36).slice(2)}`;
  private isLeader = false;

  constructor(
    private readonly presence: ActiveUsersPresenceService,
    private readonly realtime: ActiveUsersRealtimeService,
    private readonly prisma: PrismaService,
  ) {}

  async onModuleInit(): Promise<void> {
    if (process.env.ACTIVE_USERS_CRON_ENABLED === 'false') {
      this.logger.log('active users metrics cron disabled');
      return;
    }
    this.isLeader = await this.acquireLeaderLock();
    if (!this.isLeader) {
      this.logger.log('active users metrics cron not leader on this instance');
      return;
    }
    this.startLeaderLockRenewal();
    this.samplerTimer = setInterval(() => void this.sampleConcurrent(), PRESENCE_CONFIG.samplerIntervalMs);
    this.rollupTimer = setInterval(() => void this.nightlyRollupIfDue(), 60 * 60_000);
    void this.sampleConcurrent();
  }

  async onModuleDestroy(): Promise<void> {
    if (this.samplerTimer) clearInterval(this.samplerTimer);
    if (this.rollupTimer) clearInterval(this.rollupTimer);
    if (this.leaderRenewTimer) clearInterval(this.leaderRenewTimer);
    await this.releaseLeaderLock();
  }

  private async sampleConcurrent(): Promise<void> {
    try {
      const count = await this.presence.countDistinctActive();
      await this.realtime.recordConcurrentSample(count);
    } catch (error) {
      this.logger.warn(`concurrent sample failed: ${String(error)}`);
    }
  }

  private async nightlyRollupIfDue(): Promise<void> {
    const now = new Date();
    if (now.getUTCHours() !== 1) return;
    const yesterday = new Date(now);
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    yesterday.setUTCHours(0, 0, 0, 0);
    try {
      const existing = await this.prisma.dailyActiveStat.findUnique({
        where: { date: yesterday },
      });
      if (existing) return;

      const { dau, wau, mau } = await this.realtime.getDauWauMau();
      const peakToday = await this.realtime.getPeakToday();
      const avgConcurrent = await this.realtime.getAvgConcurrent();
      const start = new Date(yesterday);
      const end = new Date(yesterday);
      end.setUTCDate(end.getUTCDate() + 1);

      const [sessionsStarted, reportsSubmitted, newRegistrations] = await Promise.all([
        this.prisma.userActivityEvent.count({
          where: { type: { in: ['LOGIN', 'APP_OPENED'] }, occurredAt: { gte: start, lt: end } },
        }),
        this.prisma.userActivityEvent.count({
          where: { type: 'REPORT_SUBMITTED', occurredAt: { gte: start, lt: end } },
        }),
        this.prisma.user.count({ where: { createdAt: { gte: start, lt: end } } }),
      ]);

      await this.prisma.dailyActiveStat.create({
        data: {
          date: yesterday,
          dau,
          wau,
          mau,
          peakConcurrent: peakToday,
          avgConcurrent,
          sessionsStarted,
          reportsSubmitted,
          newRegistrations,
        },
      });
    } catch (error) {
      this.logger.warn(`nightly rollup failed: ${String(error)}`);
    }
  }

  private async acquireLeaderLock(): Promise<boolean> {
    if (!this.redis) return true;
    const result = await this.redis.set(
      ActiveUsersMetricsCronService.LEADER_LOCK_KEY,
      this.leaderToken,
      'EX',
      ActiveUsersMetricsCronService.LEADER_LOCK_TTL_SECONDS,
      'NX',
    );
    return result === 'OK';
  }

  private startLeaderLockRenewal(): void {
    if (!this.redis) return;
    this.leaderRenewTimer = setInterval(() => {
      void this.redis!
        .eval(
          `if redis.call("get", KEYS[1]) == ARGV[1] then return redis.call("expire", KEYS[1], ARGV[2]) else return 0 end`,
          1,
          ActiveUsersMetricsCronService.LEADER_LOCK_KEY,
          this.leaderToken,
          String(ActiveUsersMetricsCronService.LEADER_LOCK_TTL_SECONDS),
        )
        .catch(() => {});
    }, 10_000);
  }

  private async releaseLeaderLock(): Promise<void> {
    if (!this.redis || !this.isLeader) return;
    await this.redis.eval(
      `if redis.call("get", KEYS[1]) == ARGV[1] then return redis.call("del", KEYS[1]) else return 0 end`,
      1,
      ActiveUsersMetricsCronService.LEADER_LOCK_KEY,
      this.leaderToken,
    );
  }
}
