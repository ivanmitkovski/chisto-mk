import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ListEventsQueryDto } from './dto/list-events-query.dto';
import {
  parseCategoryFilterList,
  parseLifecycleFilterList,
} from './events-mobile.mapper';
import { decodeCursor, encodeCursor } from './events-cursors.util';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventsSearchQueryService } from './events-search-query.service';
import { EventsTelemetryService } from './events-telemetry.service';
import { eventListIncludeForViewer } from './events-query.include.list';
import { visibilityWhere } from './events-query.include.shared';
import { EventsRepository } from './events.repository';

@Injectable()
export class EventsListQueryService {
  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly mobileMapper: EventsMobileMapperService,
    private readonly eventsTelemetry: EventsTelemetryService,
    private readonly eventsSearchQuery: EventsSearchQueryService,
  ) {}

  async list(user: AuthenticatedUser, query: ListEventsQueryDto) {
    const t0 = Date.now();
    const limit = query.getLimit();
    const lifecycleFilter = parseLifecycleFilterList(query.status);
    if (query.status != null && query.status.trim() !== '' && lifecycleFilter == null) {
      throw new BadRequestException({
        code: 'INVALID_EVENT_STATUS_FILTER',
        message: 'Invalid status filter',
      });
    }

    const categoryList = parseCategoryFilterList(query.category);
    if (query.category != null && query.category.trim() !== '' && categoryList == null) {
      throw new BadRequestException({
        code: 'INVALID_EVENT_CATEGORY',
        message: 'Invalid category',
      });
    }

    if (
      (query.nearLat != null && query.nearLng == null) ||
      (query.nearLat == null && query.nearLng != null)
    ) {
      throw new BadRequestException({
        code: 'EVENTS_VIEWER_GEO_INCOMPLETE',
        message: 'nearLat and nearLng must both be provided',
      });
    }

    const searchFilter = this.eventsSearchQuery.buildListSearchWhere(query.q);

    const dateFromFilter: Prisma.CleanupEventWhereInput | null = query.dateFrom
      ? { scheduledAt: { gte: new Date(query.dateFrom) } }
      : null;
    const dateToFilter: Prisma.CleanupEventWhereInput | null = query.dateTo
      ? {
          scheduledAt: {
            lt: new Date(
              new Date(query.dateTo).setDate(new Date(query.dateTo).getDate() + 1),
            ),
          },
        }
      : null;

    const baseWhere: Prisma.CleanupEventWhereInput = {
      AND: [
        visibilityWhere(user.userId),
        ...(query.siteId?.trim()
          ? [{ siteId: query.siteId.trim() } satisfies Prisma.CleanupEventWhereInput]
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

    let cursorClause: Prisma.CleanupEventWhereInput = {};
    if (query.cursor != null && query.cursor.trim() !== '') {
      const { scheduledAt, id } = decodeCursor(query.cursor.trim());
      cursorClause = {
        OR: [
          { scheduledAt: { lt: scheduledAt } },
          { AND: [{ scheduledAt }, { id: { lt: id } }] },
        ],
      };
    }

    const where: Prisma.CleanupEventWhereInput = {
      AND: [baseWhere, cursorClause],
    };

    const rows = await this.eventsRepository.prisma.cleanupEvent.findMany({
      where,
      orderBy: [{ scheduledAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      include: eventListIncludeForViewer(user.userId),
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const last = page[page.length - 1];
    const nextCursor =
      hasMore && last != null ? encodeCursor(last.scheduledAt, last.id) : null;

    let siteDistanceBySiteId: Map<string, number> | null = null;
    if (query.hasViewerGeo()) {
      siteDistanceBySiteId = await this.eventsRepository.siteDistancesKmFromPoint(
        query.nearLat!,
        query.nearLng!,
        page.map((r) => r.siteId),
      );
    }

    const recurrenceRoots = [
      ...new Set(
        page
          .filter((r) => r.recurrenceRule != null || r.parentEventId != null)
          .map((r) => r.parentEventId ?? r.id),
      ),
    ];
    const recurrenceSeriesByRoot =
      recurrenceRoots.length > 0
        ? await this.eventsRepository.listRecurrenceSeriesEventsBatch(recurrenceRoots)
        : new Map<string, { id: string; scheduledAt: Date }[]>();

    const data = await Promise.all(
      page.map((row) =>
        this.mobileMapper.toMobileEvent(row, {
          siteDistanceKm: siteDistanceBySiteId?.get(row.siteId) ?? 0,
          recurrenceSeriesByRoot,
        }),
      ),
    );

    this.eventsTelemetry.emitSpan('events.list', {
      duration_ms: Date.now() - t0,
      limit,
      hasMore,
      returned: data.length,
    });

    return {
      data,
      meta: {
        hasMore,
        nextCursor,
      },
    };
  }
}
