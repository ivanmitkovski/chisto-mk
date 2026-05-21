import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import Redis from 'ioredis';
import { PrismaService } from '../prisma/prisma.service';
import { UserStatus } from '../prisma-client';
import { legacySnapshotGauges } from '../observability/prom-registry';

const PURGE_AFTER_MS = 30 * 24 * 60 * 60 * 1000;
const TICK_MS = 24 * 60 * 60 * 1000;
const LEADER_LOCK_KEY = 'leader:account-erasure-cron';
const LEADER_LOCK_TTL_SECONDS = 60;

@Injectable()
export class AccountErasureCronService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AccountErasureCronService.name);
  private timer: ReturnType<typeof setInterval> | null = null;
  private leaderRenewTimer: ReturnType<typeof setInterval> | null = null;
  private readonly redis = process.env.REDIS_URL?.trim()
    ? new Redis(process.env.REDIS_URL!.trim(), { lazyConnect: true })
    : null;
  private readonly leaderToken = `${process.pid}:${Math.random().toString(36).slice(2)}`;
  private isLeader = false;
  private shuttingDown = false;

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit(): Promise<void> {
    if (process.env.NODE_ENV === 'test') return;
    this.isLeader = await this.acquireLeaderLock();
    if (!this.isLeader) {
      this.logger.log('account erasure cron not elected leader on this instance');
      return;
    }
    this.startLeaderLockRenewal();
    this.timer = setInterval(() => {
      if (!this.shuttingDown) void this.purgeExpired();
    }, TICK_MS);
  }

  onModuleDestroy(): void {
    this.shuttingDown = true;
    if (this.timer) clearInterval(this.timer);
    if (this.leaderRenewTimer) clearInterval(this.leaderRenewTimer);
    void this.releaseLeaderLock();
  }

  async purgeExpired(): Promise<number> {
    if (this.shuttingDown) return 0;
    const cutoff = new Date(Date.now() - PURGE_AFTER_MS);
    const users = await this.prisma.user.findMany({
      where: {
        status: UserStatus.DELETED,
        deletedAt: { lt: cutoff },
      },
      select: { id: true },
      take: 100,
    });
    if (users.length === 0) return 0;

    const ids = users.map((u) => u.id);
    await this.prisma.$transaction([
      this.prisma.auditLog.deleteMany({ where: { actorId: { in: ids } } }),
      this.prisma.userSession.deleteMany({ where: { userId: { in: ids } } }),
      this.prisma.userDeviceToken.deleteMany({ where: { userId: { in: ids } } }),
      this.prisma.user.deleteMany({ where: { id: { in: ids } } }),
    ]);

    legacySnapshotGauges.accountErasurePurged.inc(ids.length);
    this.logger.log(`Purged ${ids.length} user(s) past 30-day erasure grace`);
    return ids.length;
  }

  private async acquireLeaderLock(): Promise<boolean> {
    if (!this.redis) {
      return process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'staging';
    }
    await this.redis.connect().catch(() => undefined);
    const response = await this.redis.set(
      LEADER_LOCK_KEY,
      this.leaderToken,
      'EX',
      LEADER_LOCK_TTL_SECONDS,
      'NX',
    );
    return response === 'OK';
  }

  private startLeaderLockRenewal(): void {
    if (!this.redis) return;
    const redis = this.redis;
    this.leaderRenewTimer = setInterval(() => {
      void redis
        .eval(
          `if redis.call("GET", KEYS[1]) == ARGV[1] then return redis.call("EXPIRE", KEYS[1], ARGV[2]) end return 0`,
          1,
          LEADER_LOCK_KEY,
          this.leaderToken,
          String(LEADER_LOCK_TTL_SECONDS),
        )
        .catch(() => undefined);
    }, 15_000);
  }

  private async releaseLeaderLock(): Promise<void> {
    if (!this.redis || !this.isLeader) return;
    await this.redis.connect().catch(() => undefined);
    await this.redis
      .eval(
        `if redis.call("GET", KEYS[1]) == ARGV[1] then return redis.call("DEL", KEYS[1]) end return 0`,
        1,
        LEADER_LOCK_KEY,
        this.leaderToken,
      )
      .catch(() => undefined);
    await this.redis.quit().catch(() => undefined);
  }
}
