import { Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';

/** Prisma entry point for CleanupEvent aggregate persistence (split from EventsService). */
@Injectable()
export class EventsRepository {
  constructor(public readonly prisma: PrismaService) {}

  /** Ordered recurrence series members (root id or children sharing parent). */
  async listRecurrenceSeriesEvents(rootId: string): Promise<{ id: string; scheduledAt: Date }[]> {
    return this.prisma.cleanupEvent.findMany({
      where: {
        OR: [{ id: rootId }, { parentEventId: rootId }],
      },
      select: { id: true, scheduledAt: true },
      orderBy: [{ scheduledAt: 'asc' }, { id: 'asc' }],
    });
  }

  /**
   * Great-circle distance from a viewer point to each site (km), via PostGIS geography.
   * Prisma cannot express ST_Distance on cast points; raw SQL is required.
   */
  async siteDistancesKmFromPoint(
    lat: number,
    lng: number,
    siteIds: string[],
  ): Promise<Map<string, number>> {
    const unique = [...new Set(siteIds)].filter((id) => id.length > 0);
    if (unique.length === 0) {
      return new Map();
    }
    const rows = await this.prisma.$queryRaw<Array<{ site_id: string; km: string | number | null }>>`
      SELECT s.id AS site_id,
        (ST_Distance(
          ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
          false
        ) / 1000.0)::float8 AS km
      FROM "Site" s
      WHERE s.id IN (${Prisma.join(unique)})
        AND s.latitude IS NOT NULL AND s.longitude IS NOT NULL
    `;
    const out = new Map<string, number>();
    for (const r of rows) {
      if (r.km == null) {
        continue;
      }
      const km = typeof r.km === 'string' ? Number.parseFloat(r.km) : r.km;
      if (Number.isFinite(km)) {
        out.set(r.site_id, km);
      }
    }
    return out;
  }
}
