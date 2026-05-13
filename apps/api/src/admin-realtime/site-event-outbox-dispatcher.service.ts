import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import type { Client } from 'pg';
import {
  isPgOutboxNotifyEnabled,
  MAP_EVENT_OUTBOX_ENQUEUED_CHANNEL,
  NOTIFY_SQL,
} from '../common/pg/outbox-pg-notify';
import { endPgOutboxListener, startPgOutboxListener } from '../common/pg/start-pg-outbox-listener';
import { loadMapConfig } from '../config/map.config';
import { PrismaService } from '../prisma/prisma.service';
import { ObservabilityStore } from '../observability/observability.store';
import { MapCdnPurgeService } from '../observability/map-cdn-purge.service';
import { SiteEvent } from './site-events.types';

@Injectable()
export class SiteEventOutboxDispatcherService implements OnModuleInit, OnModuleDestroy {
  private static readonly cfg = loadMapConfig();

  private readonly logger = new Logger(SiteEventOutboxDispatcherService.name);
  private readonly workerId = `map-outbox-${process.pid}-${randomUUID().slice(0, 6)}`;
  private timer: ReturnType<typeof setTimeout> | null = null;
  private shuttingDown = false;
  private consecutiveIdlePolls = 0;
  private publishFn: ((event: SiteEvent) => void) | null = null;
  private pgListenClient: Client | null = null;
  private mapListenWakeTimer: ReturnType<typeof setTimeout> | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly mapCdnPurge: MapCdnPurgeService,
  ) {}

  attachPublisher(publishFn: (event: SiteEvent) => void): void {
    this.publishFn = publishFn;
  }

  async enqueue(event: SiteEvent): Promise<void> {
    const id = randomUUID();
    await this.prisma.$executeRaw`
      INSERT INTO "MapEventOutbox" ("id","createdAt","updatedAt","eventId","siteId","eventType","payload","status","attempts")
      VALUES (${id}, NOW(), NOW(), ${event.eventId}, ${event.siteId}, ${event.type}, ${JSON.stringify(event)}::jsonb, 'PENDING'::"MapEventOutboxStatus", 0)
      ON CONFLICT ("eventId") DO NOTHING
    `;
    if (isPgOutboxNotifyEnabled()) {
      await this.prisma.$executeRawUnsafe(NOTIFY_SQL.mapEventOutboxEnqueued);
    }
  }

  onModuleInit(): void {
    if (this.timer != null) return;
    this.schedulePollTick(0);
    void this.startPgListener();
  }

  async onModuleDestroy(): Promise<void> {
    this.shuttingDown = true;
    if (this.mapListenWakeTimer != null) {
      clearTimeout(this.mapListenWakeTimer);
      this.mapListenWakeTimer = null;
    }
    if (this.timer != null) {
      clearTimeout(this.timer);
      this.timer = null;
    }
    await endPgOutboxListener(this.pgListenClient);
    this.pgListenClient = null;
  }

  private scheduleMapWakeFromNotify(): void {
    if (this.shuttingDown) return;
    if (this.mapListenWakeTimer != null) {
      clearTimeout(this.mapListenWakeTimer);
    }
    this.mapListenWakeTimer = setTimeout(() => {
      this.mapListenWakeTimer = null;
      this.schedulePollTick(0);
    }, 50);
  }

  private async startPgListener(): Promise<void> {
    this.pgListenClient = await startPgOutboxListener({
      channel: MAP_EVENT_OUTBOX_ENQUEUED_CHANNEL,
      logger: this.logger,
      onNotify: () => this.scheduleMapWakeFromNotify(),
    });
  }

  private schedulePollTick(delayMs: number): void {
    if (this.shuttingDown) return;
    if (this.timer != null) {
      clearTimeout(this.timer);
    }
    this.timer = setTimeout(() => {
      void this.runPollTick();
    }, delayMs);
  }

  private async runPollTick(): Promise<void> {
    if (this.shuttingDown) return;
    const hadWork = await this.processOutboxBatch();
    const base = SiteEventOutboxDispatcherService.cfg.outboxPollIntervalMs;
    if (hadWork) {
      this.consecutiveIdlePolls = 0;
    } else {
      this.consecutiveIdlePolls = Math.min(this.consecutiveIdlePolls + 1, 6);
    }
    const idleBackoff = this.consecutiveIdlePolls === 0 ? 0 : Math.min(25_000, base * this.consecutiveIdlePolls);
    const jitter = Math.floor(Math.random() * 400);
    this.schedulePollTick(base + idleBackoff + jitter);
  }

  kickNow(): void {
    if (this.shuttingDown) return;
    void this.processOutboxBatch();
  }

  /** @returns true when pending rows were claimed for dispatch (idle backoff resets). */
  private async processOutboxBatch(): Promise<boolean> {
    try {
      if (this.shuttingDown || !this.publishFn) return false;
      const now = new Date();
      const leaseExpiry = new Date(now.getTime() - SiteEventOutboxDispatcherService.cfg.outboxLeaseTtlMs);
      const leaseOwner = `${this.workerId}:${Date.now()}`;
      const pending = await this.prisma.$queryRaw<Array<{ id: string }>>`
        SELECT "id"
        FROM "MapEventOutbox"
        WHERE "status" = 'PENDING'::"MapEventOutboxStatus"
          AND ("processingAt" IS NULL OR "processingAt" <= ${leaseExpiry})
        ORDER BY "createdAt" ASC
        LIMIT ${SiteEventOutboxDispatcherService.cfg.outboxBatchSize}
      `;
      if (pending.length === 0) return false;
      const ids = pending.map((row) => row.id);
      await this.prisma.$executeRaw`
        UPDATE "MapEventOutbox"
        SET "processingAt" = ${now}, "leaseOwner" = ${leaseOwner}, "updatedAt" = NOW()
        WHERE "id" = ANY(${ids}::text[])
          AND "status" = 'PENDING'::"MapEventOutboxStatus"
          AND ("processingAt" IS NULL OR "processingAt" <= ${leaseExpiry})
      `;
      const claimed = await this.prisma.$queryRaw<Array<{ id: string; payload: SiteEvent }>>`
        SELECT "id", "payload"
        FROM "MapEventOutbox"
        WHERE "leaseOwner" = ${leaseOwner}
        ORDER BY "createdAt" ASC
      `;
      for (const row of claimed) {
        try {
          this.publishFn(row.payload);
          await this.prisma.$executeRaw`
            UPDATE "MapEventOutbox"
            SET "status" = 'DISPATCHED'::"MapEventOutboxStatus",
                "processingAt" = NULL,
                "leaseOwner" = NULL,
                "dispatchedAt" = NOW(),
                "attempts" = "attempts" + 1,
                "updatedAt" = NOW()
            WHERE "id" = ${row.id}
          `;
          ObservabilityStore.recordMapOutboxDispatch({
            failed: false,
            lagMs: Math.max(0, Date.now() - row.payload.occurredAtMs),
          });
          this.mapCdnPurge.enqueueSurrogateKeys(['map-tile', 'map-json']);
          if (Date.now() - row.payload.occurredAtMs > 5_000) {
            ObservabilityStore.recordMapSseReconnectHint();
          }
        } catch (error) {
          await this.prisma.$executeRaw`
            UPDATE "MapEventOutbox"
            SET "status" = CASE WHEN "attempts" >= 5 THEN 'FAILED'::"MapEventOutboxStatus" ELSE 'PENDING'::"MapEventOutboxStatus" END,
                "processingAt" = NULL,
                "leaseOwner" = NULL,
                "attempts" = "attempts" + 1,
                "lastError" = ${String(error)},
                "updatedAt" = NOW()
            WHERE "id" = ${row.id}
          `;
          ObservabilityStore.recordMapOutboxDispatch({
            failed: true,
            lagMs: Math.max(0, Date.now() - row.payload.occurredAtMs),
          });
        }
      }
      await this.purgeDeliveredRows();
      return claimed.length > 0;
    } catch (error) {
      this.logger.warn(`Map outbox batch processing failed: ${String(error)}`);
      return false;
    } finally {
      await this.refreshMapOutboxPendingGauge();
    }
  }

  private async refreshMapOutboxPendingGauge(): Promise<void> {
    try {
      const [row] = await this.prisma.$queryRaw<Array<{ c: bigint }>>`
        SELECT COUNT(*)::bigint AS c
        FROM "MapEventOutbox"
        WHERE "status" = 'PENDING'::"MapEventOutboxStatus"
      `;
      ObservabilityStore.setMapOutboxPendingCount(Number(row?.c ?? 0n));
    } catch {
      /* ignore gauge refresh errors */
    }
  }

  private async purgeDeliveredRows(): Promise<void> {
    const purgedDispatched = await this.prisma.$executeRaw`
      DELETE FROM "MapEventOutbox"
      WHERE "status" = 'DISPATCHED'::"MapEventOutboxStatus"
        AND "dispatchedAt" < NOW() - interval '24 hours'
    `;
    const purgedFailed = await this.prisma.$executeRaw`
      DELETE FROM "MapEventOutbox"
      WHERE "status" = 'FAILED'::"MapEventOutboxStatus"
        AND "updatedAt" < NOW() - interval '7 days'
    `;
    const total = Number(purgedDispatched) + Number(purgedFailed);
    if (total > 0) {
      ObservabilityStore.recordMapOutboxRowsPurged(total);
    }
  }

}
