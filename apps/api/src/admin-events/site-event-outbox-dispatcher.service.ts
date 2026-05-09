import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
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
  private timer: ReturnType<typeof setInterval> | null = null;
  private shuttingDown = false;
  private publishFn: ((event: SiteEvent) => void) | null = null;

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
  }

  onModuleInit(): void {
    if (this.timer != null) return;
    this.timer = setInterval(() => {
      void this.processOutboxBatch();
    }, SiteEventOutboxDispatcherService.cfg.outboxPollIntervalMs);
    void this.processOutboxBatch();
  }

  async onModuleDestroy(): Promise<void> {
    this.shuttingDown = true;
    if (this.timer != null) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  kickNow(): void {
    if (this.shuttingDown) return;
    void this.processOutboxBatch();
  }

  private async processOutboxBatch(): Promise<void> {
    if (this.shuttingDown || !this.publishFn) return;
    const now = new Date();
    const leaseExpiry = new Date(now.getTime() - SiteEventOutboxDispatcherService.cfg.outboxLeaseTtlMs);
    const leaseOwner = `${this.workerId}:${Date.now()}`;
    try {
      const pending = await this.prisma.$queryRaw<Array<{ id: string }>>`
        SELECT "id"
        FROM "MapEventOutbox"
        WHERE "status" = 'PENDING'::"MapEventOutboxStatus"
          AND ("processingAt" IS NULL OR "processingAt" <= ${leaseExpiry})
        ORDER BY "createdAt" ASC
        LIMIT ${SiteEventOutboxDispatcherService.cfg.outboxBatchSize}
      `;
      if (pending.length === 0) return;
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
    } catch (error) {
      this.logger.warn(`Map outbox batch processing failed: ${String(error)}`);
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
