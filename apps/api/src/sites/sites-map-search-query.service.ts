import { Injectable, Logger } from '@nestjs/common';
import { Prisma, SiteStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { SiteMapSearchDto } from './dto/site-map-search.dto';
import { MAP_SEARCH_KM_PER_DEGREE } from './sites-map-search-geo-intent';
import type { RawSearchRow } from './sites-map-search.types';

@Injectable()
export class SitesMapSearchQueryService {
  private readonly logger = new Logger(SitesMapSearchQueryService.name);

  constructor(private readonly prisma: PrismaService) {}

  async executeSearch(dto: SiteMapSearchDto): Promise<RawSearchRow[]> {
    const q = dto.query.trim();
    const limit = dto.limit ?? 20;

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
      dto.includeArchived === true ? Prisma.empty : Prisma.sql`AND s."isArchivedByAdmin" = false`;

    const statusClause =
      dto.statuses?.length && dto.statuses.length > 0
        ? Prisma.sql`AND s."status" IN (${Prisma.join(dto.statuses)})`
        : Prisma.empty;

    const pollutionClause =
      dto.pollutionTypes?.length && dto.pollutionTypes.length > 0
        ? Prisma.sql`AND EXISTS (
            SELECT 1 FROM "Report" r_filter
            WHERE r_filter."siteId" = s."id"
            AND r_filter."category" IN (${Prisma.join(dto.pollutionTypes)})
          )`
        : Prisma.empty;

    try {
      return await this.prisma.$queryRaw<RawSearchRow[]>(Prisma.sql`
        SELECT
          s."id",
          s."latitude",
          s."longitude",
          s."description",
          s."address",
          s."status",
          (
            ts_rank(s."searchVector", plainto_tsquery('simple', ${q})) * ${tsW}
            + similarity(
                coalesce(s."description", '') || ' ' || coalesce(s."address", ''),
                ${q}
              ) * ${simW}
            + (1.0 / (1.0 + extract(epoch FROM now() - s."updatedAt") / 86400.0)) * ${recW}
            + (1.0 / (1.0 + sqrt(
                power(s."latitude" - ${safeLat}, 2) + power(s."longitude" - ${safeLng}, 2)
              ) * ${MAP_SEARCH_KM_PER_DEGREE})) * ${proxW}
          ) AS "score",
          lr."mediaUrls" AS "latestReportMediaUrls"
        FROM "Site" AS s
        LEFT JOIN LATERAL (
          SELECT r."mediaUrls"
          FROM "Report" r
          WHERE r."siteId" = s."id"
          ORDER BY r."createdAt" DESC
          LIMIT 1
        ) AS lr ON true
        WHERE
          (
            s."searchVector" @@ plainto_tsquery('simple', ${q})
            OR similarity(
                 coalesce(s."description", '') || ' ' || coalesce(s."address", ''),
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
      return this.ilikeFallback(q, limit, dto);
    }
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
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: { mediaUrls: true },
        },
      },
    });
    return rows.map((r) => {
      const { reports, ...site } = r;
      const latest = reports[0]?.mediaUrls ?? [];
      return {
        ...site,
        latestReportMediaUrls: latest.length > 0 ? latest : null,
        score: 0,
      };
    });
  }
}
