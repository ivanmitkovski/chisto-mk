import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { NotificationType, Prisma } from '../prisma-client';
import { NotificationDispatcherService } from '../notifications/notification-dispatcher.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  END_SOON_WINDOW_END_MS,
  END_SOON_WINDOW_START_MS,
} from './event-schedule-policy.constants';

const TICK_MS = 60_000;

export type EndSoonClaimRow = {
  id: string;
  organizerId: string | null;
  title: string;
  endAt: Date;
};

@Injectable()
export class EventEndSoonNotifierService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(EventEndSoonNotifierService.name);
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly dispatcher: NotificationDispatcherService,
  ) {}

  onModuleInit(): void {
    this.timer = setInterval(() => {
      void this.tick().catch((err: unknown) => {
        this.logger.error(`event end-soon tick failed: ${String(err)}`);
      });
    }, TICK_MS);
    this.logger.log('Event end-soon notifier started');
  }

  onModuleDestroy(): void {
    if (this.timer != null) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /** Exposed for tests (fixed clock). */
  async tickAt(now: Date): Promise<void> {
    const windowStart = new Date(now.getTime() + END_SOON_WINDOW_START_MS);
    const windowEnd = new Date(now.getTime() + END_SOON_WINDOW_END_MS);

    const claimed = await this.prisma.$queryRaw<EndSoonClaimRow[]>(Prisma.sql`
      WITH pick AS (
        SELECT c.id
        FROM "CleanupEvent" c
        WHERE c."lifecycleStatus" = 'IN_PROGRESS'::"EcoEventLifecycleStatus"
          AND c."status" = 'APPROVED'::"CleanupEventStatus"
          AND c."endAt" IS NOT NULL
          AND c."endAt" >= ${windowStart}
          AND c."endAt" <= ${windowEnd}
          AND c."organizerId" IS NOT NULL
          AND (c."endSoonNotifiedForEndAt" IS DISTINCT FROM c."endAt")
        ORDER BY c."endAt" ASC
        FOR UPDATE SKIP LOCKED
        LIMIT 8
      )
      UPDATE "CleanupEvent" c
      SET "endSoonNotifiedForEndAt" = c."endAt"
      FROM pick
      WHERE c.id = pick.id
      RETURNING c.id, c."organizerId", c.title, c."endAt"
    `);

    for (const row of claimed) {
      const organizerId = row.organizerId?.trim() ?? '';
      if (organizerId.length === 0) {
        continue;
      }
      const title = 'Наскоро крај на чистењето';
      const safeTitle = row.title.length > 120 ? `${row.title.slice(0, 117)}…` : row.title;
      const body = `„${safeTitle}“ завршува за околу 10 минути. Ако ви треба повеќе време, продолжете го крајот во апликацијата.`;
      try {
        await this.dispatcher.dispatchToUser(organizerId, {
          title,
          body,
          type: NotificationType.CLEANUP_EVENT,
          data: {
            eventId: row.id,
            endAt: row.endAt.toISOString(),
            kind: 'cleanup_ending_soon',
          },
          groupKey: `EVENT_END_SOON:${row.id}`,
          threadKey: `event:${row.id}`,
        });
      } catch (err: unknown) {
        this.logger.warn(`end-soon dispatch failed for event ${row.id}: ${String(err)}`);
      }
    }
  }

  private async tick(): Promise<void> {
    await this.tickAt(new Date());
  }
}
