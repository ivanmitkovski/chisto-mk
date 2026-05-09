import { Injectable, Logger } from '@nestjs/common';
import { Prisma, SiteStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { SiteMapSearchDto } from './dto/site-map-search.dto';

export type SiteMapSearchItem = {
  id: string;
  latitude: number;
  longitude: number;
  description: string | null;
  address: string | null;
  status: SiteStatus;
};

export type GeoIntentBounds = {
  label: string;
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
};

export type SiteMapSearchResponse = {
  items: SiteMapSearchItem[];
  suggestions: string[];
  geoIntent: GeoIntentBounds | null;
};

type RawSearchRow = {
  id: string;
  latitude: number;
  longitude: number;
  description: string | null;
  address: string | null;
  status: SiteStatus;
  score: number;
};

type GeoIntentEntry = {
  aliases: string[];
  bounds: GeoIntentBounds;
};

/**
 * Covers all major Macedonian cities/municipalities with both Latin and
 * Cyrillic name variants. Bounding boxes are generous enough to be useful
 * for the client map viewport.
 */
const GEO_INTENT_CATALOG: GeoIntentEntry[] = [
  {
    aliases: ['skopje', 'скопје'],
    bounds: { label: 'Skopje', minLat: 41.93, maxLat: 42.07, minLng: 21.33, maxLng: 21.57 },
  },
  {
    aliases: ['bitola', 'битола'],
    bounds: { label: 'Bitola', minLat: 40.98, maxLat: 41.08, minLng: 21.28, maxLng: 21.42 },
  },
  {
    aliases: ['ohrid', 'охрид'],
    bounds: { label: 'Ohrid', minLat: 41.06, maxLat: 41.16, minLng: 20.75, maxLng: 20.85 },
  },
  {
    aliases: ['prilep', 'прилеп'],
    bounds: { label: 'Prilep', minLat: 41.28, maxLat: 41.40, minLng: 21.50, maxLng: 21.62 },
  },
  {
    aliases: ['kumanovo', 'куманово'],
    bounds: { label: 'Kumanovo', minLat: 42.08, maxLat: 42.18, minLng: 21.67, maxLng: 21.81 },
  },
  {
    aliases: ['tetovo', 'тетово'],
    bounds: { label: 'Tetovo', minLat: 41.98, maxLat: 42.06, minLng: 20.90, maxLng: 21.02 },
  },
  {
    aliases: ['veles', 'велес'],
    bounds: { label: 'Veles', minLat: 41.68, maxLat: 41.77, minLng: 21.73, maxLng: 21.82 },
  },
  {
    aliases: ['stip', 'shtip', 'штип'],
    bounds: { label: 'Shtip', minLat: 41.70, maxLat: 41.78, minLng: 22.15, maxLng: 22.24 },
  },
  {
    aliases: ['strumica', 'струмица'],
    bounds: { label: 'Strumica', minLat: 41.40, maxLat: 41.50, minLng: 22.60, maxLng: 22.70 },
  },
  {
    aliases: ['gostivar', 'гостивар'],
    bounds: { label: 'Gostivar', minLat: 41.76, maxLat: 41.84, minLng: 20.86, maxLng: 20.97 },
  },
  {
    aliases: ['kavadarci', 'кавадарци'],
    bounds: { label: 'Kavadarci', minLat: 41.40, maxLat: 41.48, minLng: 21.98, maxLng: 22.05 },
  },
  {
    aliases: ['kochani', 'кочани'],
    bounds: { label: 'Kochani', minLat: 41.87, maxLat: 41.96, minLng: 22.36, maxLng: 22.46 },
  },
  {
    aliases: ['kichevo', 'кичево'],
    bounds: { label: 'Kichevo', minLat: 41.48, maxLat: 41.55, minLng: 20.91, maxLng: 21.00 },
  },
  {
    aliases: ['struga', 'струга'],
    bounds: { label: 'Struga', minLat: 41.13, maxLat: 41.22, minLng: 20.63, maxLng: 20.72 },
  },
  {
    aliases: ['gevgelija', 'гевгелија'],
    bounds: { label: 'Gevgelija', minLat: 41.11, maxLat: 41.18, minLng: 22.46, maxLng: 22.54 },
  },
  {
    aliases: ['negotino', 'неготино'],
    bounds: { label: 'Negotino', minLat: 41.45, maxLat: 41.52, minLng: 22.06, maxLng: 22.14 },
  },
  {
    aliases: ['debar', 'дебар'],
    bounds: { label: 'Debar', minLat: 41.49, maxLat: 41.56, minLng: 20.49, maxLng: 20.56 },
  },
  {
    aliases: ['kratovo', 'кратово'],
    bounds: { label: 'Kratovo', minLat: 42.05, maxLat: 42.12, minLng: 22.15, maxLng: 22.22 },
  },
  {
    aliases: ['krusevo', 'крушево'],
    bounds: { label: 'Krusevo', minLat: 41.33, maxLat: 41.41, minLng: 21.22, maxLng: 21.29 },
  },
  {
    aliases: ['demir hisar', 'демир хисар'],
    bounds: { label: 'Demir Hisar', minLat: 41.18, maxLat: 41.25, minLng: 21.16, maxLng: 21.24 },
  },
  {
    aliases: ['resen', 'ресен'],
    bounds: { label: 'Resen', minLat: 41.05, maxLat: 41.13, minLng: 20.98, maxLng: 21.06 },
  },
  {
    aliases: ['probistip', 'пробиштип'],
    bounds: { label: 'Probistip', minLat: 41.95, maxLat: 42.03, minLng: 22.14, maxLng: 22.22 },
  },
  {
    aliases: ['sveti nikole', 'свети николе'],
    bounds: { label: 'Sveti Nikole', minLat: 41.82, maxLat: 41.90, minLng: 21.91, maxLng: 21.99 },
  },
  {
    aliases: ['berovo', 'берово'],
    bounds: { label: 'Berovo', minLat: 41.68, maxLat: 41.75, minLng: 22.81, maxLng: 22.89 },
  },
  {
    aliases: ['radovis', 'radovish', 'радовиш'],
    bounds: { label: 'Radovis', minLat: 41.61, maxLat: 41.68, minLng: 22.43, maxLng: 22.51 },
  },
  {
    aliases: ['valandovo', 'валандово'],
    bounds: { label: 'Valandovo', minLat: 41.28, maxLat: 41.36, minLng: 22.52, maxLng: 22.60 },
  },
  {
    aliases: ['delcevo', 'делчево'],
    bounds: { label: 'Delcevo', minLat: 41.94, maxLat: 42.01, minLng: 22.74, maxLng: 22.82 },
  },
  {
    aliases: ['vinica', 'виница'],
    bounds: { label: 'Vinica', minLat: 41.85, maxLat: 41.92, minLng: 22.46, maxLng: 22.54 },
  },
  {
    aliases: ['makedonski brod', 'македонски брод'],
    bounds: { label: 'Makedonski Brod', minLat: 41.48, maxLat: 41.56, minLng: 21.20, maxLng: 21.28 },
  },
];

/** Approximate km-per-degree at Macedonian latitudes (~41°N). */
const KM_PER_DEGREE = 111.0;

@Injectable()
export class SitesSearchService {
  private readonly logger = new Logger(SitesSearchService.name);

  constructor(private readonly prisma: PrismaService) {}

  async searchMapSites(dto: SiteMapSearchDto): Promise<SiteMapSearchResponse> {
    const q = dto.query.trim();
    const limit = dto.limit ?? 20;
    if (q.length === 0) {
      return { items: [], suggestions: [], geoIntent: null };
    }

    const geoIntent = this.resolveGeoIntent(q);

    const lat = dto.lat;
    const lng = dto.lng;
    const hasProximity = lat !== undefined && lng !== undefined;
    const tsW = hasProximity ? 0.45 : 0.6;
    const simW = hasProximity ? 0.2 : 0.25;
    const recW = 0.15;
    const proxW = hasProximity ? 0.2 : 0.0;
    const safeLat = lat ?? 0;
    const safeLng = lng ?? 0;

    const archiveClause =
      dto.includeArchived === true ? Prisma.empty : Prisma.sql`AND "isArchivedByAdmin" = false`;

    const statusClause =
      dto.statuses?.length && dto.statuses.length > 0
        ? Prisma.sql`AND "status" IN (${Prisma.join(dto.statuses)})`
        : Prisma.empty;

    const pollutionClause =
      dto.pollutionTypes?.length && dto.pollutionTypes.length > 0
        ? Prisma.sql`AND EXISTS (
            SELECT 1 FROM "Report" r
            WHERE r."siteId" = "Site"."id"
            AND r."category" IN (${Prisma.join(dto.pollutionTypes)})
          )`
        : Prisma.empty;

    let rows: RawSearchRow[];
    try {
      rows = await this.prisma.$queryRaw<RawSearchRow[]>(Prisma.sql`
        SELECT
          "id",
          "latitude",
          "longitude",
          "description",
          "address",
          "status",
          (
            ts_rank("searchVector", plainto_tsquery('simple', ${q})) * ${tsW}
            + similarity(
                coalesce("description", '') || ' ' || coalesce("address", ''),
                ${q}
              ) * ${simW}
            + (1.0 / (1.0 + extract(epoch FROM now() - "updatedAt") / 86400.0)) * ${recW}
            + (1.0 / (1.0 + sqrt(
                power("latitude" - ${safeLat}, 2) + power("longitude" - ${safeLng}, 2)
              ) * ${KM_PER_DEGREE})) * ${proxW}
          ) AS "score"
        FROM "Site"
        WHERE
          (
            "searchVector" @@ plainto_tsquery('simple', ${q})
            OR similarity(
                 coalesce("description", '') || ' ' || coalesce("address", ''),
                 ${q}
               ) > 0.15
          )
          ${archiveClause}
          ${statusClause}
          ${pollutionClause}
        ORDER BY "score" DESC
        LIMIT ${limit}
      `);
    } catch (error) {
      this.logger.error('Full-text search query failed, falling back to ILIKE', error);
      rows = await this.ilikeFallback(q, limit, dto);
    }

    const items: SiteMapSearchItem[] = rows.map(({ score: _, ...rest }) => rest);
    const suggestions = this.extractSuggestions(rows);

    return { items, suggestions, geoIntent };
  }

  private extractSuggestions(rows: RawSearchRow[]): string[] {
    const seen = new Set<string>();
    const result: string[] = [];
    for (const row of rows) {
      if (result.length >= 3) break;
      const addr = row.address?.trim();
      if (addr && !seen.has(addr)) {
        seen.add(addr);
        result.push(addr);
      }
    }
    return result;
  }

  /**
   * Graceful degradation when the pg_trgm extension or tsvector column is
   * not yet available (e.g. migration pending). Uses the original ILIKE
   * approach without ranking.
   */
  private async ilikeFallback(q: string, limit: number, dto: SiteMapSearchDto): Promise<RawSearchRow[]> {
    const where: Record<string, unknown> = {
      OR: [
        { description: { contains: q, mode: 'insensitive' } },
        { address: { contains: q, mode: 'insensitive' } },
      ],
    };
    if (dto.includeArchived !== true) {
      where.isArchivedByAdmin = false;
    }
    if (dto.statuses?.length) {
      where.status = { in: dto.statuses as SiteStatus[] };
    }
    if (dto.pollutionTypes?.length) {
      where.reports = {
        some: {
          category: { in: dto.pollutionTypes },
        },
      };
    }
    const rows = await this.prisma.site.findMany({
      where: where as never,
      take: limit,
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        latitude: true,
        longitude: true,
        description: true,
        address: true,
        status: true,
      },
    });
    return rows.map((r) => ({ ...r, score: 0 }));
  }

  private resolveGeoIntent(q: string): GeoIntentBounds | null {
    const lower = q.toLowerCase();
    for (const entry of GEO_INTENT_CATALOG) {
      if (entry.aliases.some((alias) => lower.includes(alias))) {
        return entry.bounds;
      }
    }
    return null;
  }
}
