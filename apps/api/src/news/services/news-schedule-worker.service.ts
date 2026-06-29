import { BadRequestException, Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import Redis from 'ioredis';
import { AuditService } from '../../audit/services/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { WorkerHeartbeatRegistry } from '../../observability/worker-heartbeat.registry';
import { NewsPostsLifecycleService } from './news-posts-lifecycle.service';
import { NewsRevalidateService } from './news-revalidate.service';

const POLL_MS = 60_000;
const WORKER_NAME = 'news-schedule';
const LEADER_LOCK_KEY = 'leader:news-schedule-worker';
const LEADER_LOCK_TTL_SECONDS = 90;
const DUE_BATCH_SIZE = 10;

@Injectable()
export class NewsScheduleWorkerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(NewsScheduleWorkerService.name);
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
    private readonly prisma: PrismaService,
    private readonly lifecycle: NewsPostsLifecycleService,
    private readonly revalidate: NewsRevalidateService,
    private readonly audit?: AuditService,
  ) {}

  async onModuleInit(): Promise<void> {
    if (process.env.NODE_ENV === 'test') return;

    this.isLeader = await this.acquireLeaderLock();
    if (!this.isLeader) {
      this.logger.log('news schedule worker not elected leader on this instance');
      return;
    }

    this.startLeaderLockRenewal();
    WorkerHeartbeatRegistry.markStarted({ name: WORKER_NAME, intervalMs: POLL_MS });
    this.timer = setInterval(() => {
      if (!this.shuttingDown) void this.runTick();
    }, POLL_MS);
    void this.runTick();
    this.logger.log('News schedule worker started');
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
      const now = new Date();
      const due = await this.prisma.newsPost.findMany({
        where: {
          status: 'SCHEDULED',
          scheduledAt: { lte: now },
        },
        take: DUE_BATCH_SIZE,
        orderBy: { scheduledAt: 'asc' },
      });

      for (const post of due) {
        try {
          await this.lifecycle.publish(post.id);
          this.logger.log(`news scheduled publish: ${post.slug}`);
        } catch (err) {
          const message = (err as Error).message;
          this.logger.warn(`news scheduled publish failed ${post.slug}: ${message}`);
          if (err instanceof BadRequestException) {
            await this.prisma.newsPost.update({
              where: { id: post.id },
              data: { status: 'DRAFT', scheduledAt: null },
            });
            await this.audit?.log({
              actorId: null,
              action: 'news.schedule.failed',
              resourceType: 'NewsPost',
              resourceId: post.id,
              metadata: { slug: post.slug, error: message },
            });
          }
        }
      }

      if (due.length > 0) {
        void this.revalidate.triggerLandingRevalidate();
      }
    } catch (err) {
      this.logger.error(`news schedule tick failed: ${(err as Error).message}`);
    } finally {
      this.tickInFlight = false;
    }
  }

  private async acquireLeaderLock(): Promise<boolean> {
    if (!this.redis) {
      this.logger.warn(
        'news schedule worker disabled: REDIS_URL not set (leader election required)',
      );
      return false;
    }
    try {
      if (!this.redis.status || this.redis.status === 'wait') await this.redis.connect();
      const result = await this.redis.set(
        LEADER_LOCK_KEY,
        this.leaderToken,
        'EX',
        LEADER_LOCK_TTL_SECONDS,
        'NX',
      );
      return result === 'OK';
    } catch (err) {
      this.logger.warn(`news schedule leader lock failed: ${(err as Error).message}`);
      return false;
    }
  }

  private startLeaderLockRenewal(): void {
    if (!this.redis) return;
    this.leaderRenewTimer = setInterval(() => {
      void this.renewLeaderLock();
    }, (LEADER_LOCK_TTL_SECONDS * 1000) / 2);
  }

  private async renewLeaderLock(): Promise<void> {
    if (!this.redis || !this.isLeader) return;
    try {
      const current = await this.redis.get(LEADER_LOCK_KEY);
      if (current !== this.leaderToken) {
        this.isLeader = false;
        return;
      }
      await this.redis.expire(LEADER_LOCK_KEY, LEADER_LOCK_TTL_SECONDS);
    } catch (err) {
      this.logger.warn(`news schedule leader renew failed: ${(err as Error).message}`);
    }
  }

  private async releaseLeaderLock(): Promise<void> {
    if (!this.redis) return;
    try {
      const current = await this.redis.get(LEADER_LOCK_KEY);
      if (current === this.leaderToken) {
        await this.redis.del(LEADER_LOCK_KEY);
      }
    } catch {
      // best effort
    }
  }
}
