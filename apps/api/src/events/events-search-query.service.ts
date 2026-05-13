import { Injectable, Logger } from '@nestjs/common';
import {
  EcoEventCategory,
  EcoEventLifecycleStatus,
  Prisma,
} from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { EventSearchDto } from './dto/event-search.dto';
import { visibilityWhere } from './events-query.include.shared';
import { EventsRepository } from './events.repository';

const KM_PER_DEGREE = 111.0;

export type EventsSearchRawRow = {
  id: string;
  score: number;
  latestReportMediaUrls: string[] | null;
};

/**
 * Ranked / fallback SQL for event text search (used by {@link EventsSearchService}).
 */
@Injectable()
export class EventsSearchQueryService {
  private readonly logger = new Logger(EventsSearchQueryService.name);

  constructor(private readonly eventsRepository: EventsRepository) {}

  /**
   * Case-insensitive substring match on title OR description (minimum 2 chars).
   * Returns null when search should not narrow results.
   */
  buildListSearchWhere(q: string | undefined | null): Prisma.CleanupEventWhereInput | null {
    const searchTerm = q?.trim();
    if (!searchTerm || searchTerm.length < 2) {
      return null;
    }
    return {
      OR: [
        { title: { contains: searchTerm, mode: 'insensitive' } },
        { description: { contains: searchTerm, mode: 'insensitive' } },
      ],
    };
  }

  /**
   * Full-text ranked rows (or ILIKE fallback). Caller validates `dto` filters.
   */
  async fetchRankedCandidateRows(
    user: AuthenticatedUser,
    dto: EventSearchDto,
    queryTerm: string,
    limit: number,
    lifecycleFilter: EcoEventLifecycleStatus[] | null,
    categoryList: EcoEventCategory[] | null,
  ): Promise<EventsSearchRawRow[]> {
    const hasProximity = dto.nearLat != null && dto.nearLng != null;
    const tsW = hasProximity ? 0.45 : 0.6;
    const simW = hasProximity ? 0.2 : 0.25;
    const recW = 0.15;
    const proxW = hasProximity ? 0.2 : 0.0;
    const safeLat = dto.nearLat ?? 0;
    const safeLng = dto.nearLng ?? 0;

    const viewerId = user.userId;
    const visibilitySql =
      viewerId != null && viewerId !== ''
        ? Prisma.sql`(e."status" = 'APPROVED'::"CleanupEventStatus" OR e."organizerId" = ${viewerId})`
        : Prisma.sql`e."status" = 'APPROVED'::"CleanupEventStatus"`;

    const lifecycleClause =
      lifecycleFilter != null && lifecycleFilter.length > 0
        ? Prisma.sql`AND e."lifecycleStatus" IN (${Prisma.join(lifecycleFilter)})`
        : Prisma.empty;

    const categoryClause =
      categoryList != null && categoryList.length > 0
        ? Prisma.sql`AND e."category" IN (${Prisma.join(categoryList)})`
        : Prisma.empty;

    const siteClause = dto.siteId?.trim()
      ? Prisma.sql`AND e."siteId" = ${dto.siteId.trim()}`
      : Prisma.empty;

    const dateFromClause = dto.dateFrom
      ? Prisma.sql`AND e."scheduledAt" >= ${new Date(dto.dateFrom)}`
      : Prisma.empty;
    const dateToClause = dto.dateTo
      ? Prisma.sql`AND e."scheduledAt" < ${new Date(
          new Date(dto.dateTo).setDate(new Date(dto.dateTo).getDate() + 1),
        )}`
      : Prisma.empty;

    let rows: EventsSearchRawRow[];
    try {
      rows = await this.eventsRepository.prisma.$queryRaw<EventsSearchRawRow[]>(Prisma.sql`
        SELECT
          e."id",
          (
            ts_rank(e."searchVector", plainto_tsquery('simple', ${queryTerm})) * ${tsW}
            + similarity(
                coalesce(e."title", '') || ' ' || coalesce(e."description", ''),
                ${queryTerm}
              ) * ${simW}
            + (1.0 / (1.0 + extract(epoch FROM now() - e."updatedAt") / 86400.0)) * ${recW}
            + (1.0 / (1.0 + sqrt(
                power(s."latitude" - ${safeLat}, 2) + power(s."longitude" - ${safeLng}, 2)
              ) * ${KM_PER_DEGREE})) * ${proxW}
          ) AS "score",
          lr."mediaUrls" AS "latestReportMediaUrls"
        FROM "CleanupEvent" e
        INNER JOIN "Site" s ON s."id" = e."siteId"
        LEFT JOIN LATERAL (
          SELECT r."mediaUrls"
          FROM "Report" r
          WHERE r."siteId" = e."siteId"
          ORDER BY r."createdAt" DESC
          LIMIT 1
        ) lr ON true
        WHERE
          (
            e."searchVector" @@ plainto_tsquery('simple', ${queryTerm})
            OR similarity(
                 coalesce(e."title", '') || ' ' || coalesce(e."description", ''),
                 ${queryTerm}
               ) > 0.15
          )
          AND ${visibilitySql}
          ${lifecycleClause}
          ${categoryClause}
          ${siteClause}
          ${dateFromClause}
          ${dateToClause}
        ORDER BY "score" DESC
        LIMIT ${limit}
      `);
    } catch (error) {
      this.logger.error('Event full-text search failed, falling back to ILIKE', error);
      rows = await this.ilikeSearchFallback(
        user,
        dto,
        queryTerm,
        limit,
        lifecycleFilter,
        categoryList,
      );
    }

    return rows;
  }

  private async ilikeSearchFallback(
    user: AuthenticatedUser,
    dto: EventSearchDto,
    q: string,
    limit: number,
    lifecycleFilter: EcoEventLifecycleStatus[] | null,
    categoryList: EcoEventCategory[] | null,
  ): Promise<EventsSearchRawRow[]> {
    const searchFilter = this.buildListSearchWhere(q);
    const dateFromFilter: Prisma.CleanupEventWhereInput | null = dto.dateFrom
      ? { scheduledAt: { gte: new Date(dto.dateFrom) } }
      : null;
    const dateToFilter: Prisma.CleanupEventWhereInput | null = dto.dateTo
      ? {
          scheduledAt: {
            lt: new Date(new Date(dto.dateTo).setDate(new Date(dto.dateTo).getDate() + 1)),
          },
        }
      : null;
    const baseWhere: Prisma.CleanupEventWhereInput = {
      AND: [
        visibilityWhere(user.userId),
        ...(dto.siteId?.trim()
          ? [{ siteId: dto.siteId.trim() } satisfies Prisma.CleanupEventWhereInput]
          : []),
        ...(lifecycleFilter != null && lifecycleFilter.length > 0
          ? [{ lifecycleStatus: { in: lifecycleFilter } }]
          : []),
        ...(categoryList != null && categoryList.length > 0
          ? [{ category: { in: categoryList } } satisfies Prisma.CleanupEventWhereInput]
          : []),
        ...(searchFilter != null ? [searchFilter] : []),
        ...(dateFromFilter != null ? [dateFromFilter] : []),
        ...(dateToFilter != null ? [dateToFilter] : []),
      ],
    };
    const found = await this.eventsRepository.prisma.cleanupEvent.findMany({
      where: baseWhere,
      orderBy: [{ scheduledAt: 'desc' }, { id: 'desc' }],
      take: limit,
      select: { id: true },
    });
    return found.map((r) => ({ id: r.id, score: 0, latestReportMediaUrls: null }));
  }
}
