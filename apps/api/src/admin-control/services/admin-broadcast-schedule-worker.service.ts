import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import Redis from 'ioredis';
import { AdminBroadcastsDispatchService } from './admin-broadcasts-dispatch.service';
import { AdminBroadcastsService } from './admin-broadcasts.service';
import { WorkerHeartbeatRegistry } from '../../observability/worker-heartbeat.registry';

const POLL_MS = 60_000;
const WORKER_NAME = 'broadcast-schedule';
const LEADER_LOCK_KEY = 'leader:admin-broadcast-schedule-worker';
const LEADER_LOCK_TTL_SECONDS = 90;
const DUE_BATCH_SIZE = 10;

@Injectable()
export class AdminBroadcastScheduleWorkerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AdminBroadcastScheduleWorkerService.name);
  private timer: ReturnType<typeof setInterval> | null = null;
  private leaderRenewTimer: ReturnType<typeof setInterval> | null = null;
  private readonly redis = process.env.REDIS_URL?.trim()
    ? new Redis(process.env.REDIS_URL!.trim(), { lazyConnect: true })
    : null;
  private readonly leaderToken = `${process.pid}:${Math.random().toString(36).slice(2)}`;
  private isLeader = false;
  private shuttingDown = false;
  private tickInFlight = false;

  constructor(
    private readonly broadcasts: AdminBroadcastsService,
    private readonly dispatch: AdminBroadcastsDispatchService,
  ) {}

  async onModuleInit(): Promise<void> {
    if (process.env.NODE_ENV === 'test') return;

    this.isLeader = await this.acquireLeaderLock();
    if (!this.isLeader) {
      this.logger.log('broadcast schedule worker not elected leader on this instance');
      return;
    }

    this.startLeaderLockRenewal();
    WorkerHeartbeatRegistry.markStarted({ name: WORKER_NAME, intervalMs: POLL_MS });
    this.timer = setInterval(() => {
      if (!this.shuttingDown) void this.runTick();
    }, POLL_MS);
    void this.runTick();
    this.logger.log('Admin broadcast schedule worker started');
  }

  onModuleDestroy(): void {
    this.shuttingDown = true;
    WorkerHeartbeatRegistry.markStopped(WORKER_NAME);
    if (this.timer) clearInterval(this.timer);
    if (this.leaderRenewTimer) clearInterval(this.leaderRenewTimer);
    void this.releaseLeaderLock();
  }

  async runTick(): Promise<void> {
    if (this.shuttingDown || this.tickInFlight || !this.isLeader) return;
    this.tickInFlight = true;
    try {
      const due = await this.broadcasts.listDueScheduled(DUE_BATCH_SIZE);
      for (const campaign of due) {
        if (this.shuttingDown) break;
        try {
          const result = await this.dispatch.send(campaign.id);
          this.logger.log(
            `Auto-sent scheduled broadcast ${campaign.id}: sent=${result.sentCount} failed=${result.failedCount}`,
          );
        } catch (err) {
          const message = err instanceof Error ? err.message : String(err);
          this.logger.warn(`Failed to auto-send broadcast ${campaign.id}: ${message}`);
        }
      }
      WorkerHeartbeatRegistry.record(WORKER_NAME, { ok: true });
    } catch (err) {
      WorkerHeartbeatRegistry.record(WORKER_NAME, {
        ok: false,
        error: err instanceof Error ? err.message : String(err),
      });
    } finally {
      this.tickInFlight = false;
    }
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
    }, 30_000);
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
  }
}
