import { Injectable } from '@nestjs/common';
import { loadMapConfig, MapConfig } from '../config/map.config';
import { PrismaService } from '../prisma/prisma.service';
import { SiteEvent } from './site-events.types';

@Injectable()
export class SiteEventReplayStoreService {
  private static readonly cfg: MapConfig = loadMapConfig();

  constructor(private readonly prisma: PrismaService) {}

  async getReplaySinceFromDatabase(lastEventId: string): Promise<SiteEvent[]> {
    try {
      const rows = await this.prisma.$queryRaw<Array<{ payload: SiteEvent }>>`
        WITH anchor AS (
          SELECT "createdAt" AS anchor_created_at
          FROM "MapEventOutbox"
          WHERE "eventId" = ${lastEventId}
          LIMIT 1
        )
        SELECT "payload"
        FROM "MapEventOutbox"
        WHERE "createdAt" > COALESCE((SELECT anchor_created_at FROM anchor), NOW() + interval '10 years')
          AND "createdAt" >= NOW() - (${SiteEventReplayStoreService.cfg.replayWindowMinutes} * interval '1 minute')
        ORDER BY "createdAt" ASC
        LIMIT ${SiteEventReplayStoreService.cfg.replayLimit}
      `;
      return rows.map((row) => row.payload);
    } catch {
      return [];
    }
  }
}
