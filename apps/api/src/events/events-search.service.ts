import { BadRequestException, Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { Prisma } from '../prisma-client';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { EventSearchDto } from './dto/event-search.dto';
import {
  parseCategoryFilterList,
  parseLifecycleFilterList,
} from './events-mobile.mapper';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { eventListIncludeForViewer } from './events-query.include.list';
import { EventsRepository } from './events.repository';
import { EventsSearchQueryService } from './events-search-query.service';
import type { EventsSearchRawRow } from './events-search-query.service';

/**
 * Text search for cleanup events (list feed + ranked POST /events/search).
 * Delegates SQL to {@link EventsSearchQueryService}.
 */
@Injectable()
export class EventsSearchService {
  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly uploads: ReportsUploadService,
    private readonly mobileMapper: EventsMobileMapperService,
    private readonly searchQuery: EventsSearchQueryService,
  ) {}

  buildListSearchWhere(q: string | undefined | null): Prisma.CleanupEventWhereInput | null {
    return this.searchQuery.buildListSearchWhere(q);
  }

  /**
   * Ranked search for mobile/admin (POST /events/search). Falls back to Prisma ILIKE if FTS is unavailable.
   */
  async search(user: AuthenticatedUser, dto: EventSearchDto): Promise<{
    data: unknown[];
    meta: { hasMore: boolean; nextCursor: null };
    suggestions: string[];
  }> {
    const queryTerm = dto.query.trim();
    const limit = dto.getLimit();
    const lifecycleFilter = parseLifecycleFilterList(dto.status);
    if (dto.status != null && dto.status.trim() !== '' && lifecycleFilter == null) {
      throw new BadRequestException({
        code: 'INVALID_EVENT_STATUS_FILTER',
        message: 'Invalid status filter',
      });
    }
    const categoryList = parseCategoryFilterList(dto.category);
    if (dto.category != null && dto.category.trim() !== '' && categoryList == null) {
      throw new BadRequestException({
        code: 'INVALID_EVENT_CATEGORY',
        message: 'Invalid category',
      });
    }
    if (
      (dto.nearLat != null && dto.nearLng == null) ||
      (dto.nearLat == null && dto.nearLng != null)
    ) {
      throw new BadRequestException({
        code: 'EVENTS_VIEWER_GEO_INCOMPLETE',
        message: 'nearLat and nearLng must both be provided',
      });
    }

    const hasProximity = dto.nearLat != null && dto.nearLng != null;

    const rows: EventsSearchRawRow[] = await this.searchQuery.fetchRankedCandidateRows(
      user,
      dto,
      queryTerm,
      limit,
      lifecycleFilter,
      categoryList,
    );

    const signedRows = await Promise.all(
      rows.map(async (row) => {
        const raw = row.latestReportMediaUrls ?? [];
        const signed = raw.length > 0 ? await this.uploads.signUrls(raw) : [];
        return { id: row.id, signed };
      }),
    );
    const idOrder = signedRows.map((r) => r.id);
    const signedById = new Map(signedRows.map((r) => [r.id, r.signed]));

    if (idOrder.length === 0) {
      return {
        data: [],
        meta: { hasMore: false, nextCursor: null },
        suggestions: [],
      };
    }

    const loaded = await this.eventsRepository.prisma.cleanupEvent.findMany({
      where: { id: { in: idOrder } },
      include: eventListIncludeForViewer(user.userId),
    });
    const byId = new Map(loaded.map((e) => [e.id, e]));
    const ordered = idOrder.map((id) => byId.get(id)).filter((e): e is NonNullable<typeof e> => e != null);

    const suggestions: string[] = [];
    const seenTitles = new Set<string>();
    const qLower = queryTerm.toLowerCase();
    for (const row of ordered) {
      const t = row.title.trim();
      if (t.length > 0 && !seenTitles.has(t) && t.toLowerCase().includes(qLower)) {
        seenTitles.add(t);
        suggestions.push(t);
        if (suggestions.length >= 3) {
          break;
        }
      }
    }

    let siteDistanceBySiteId: Map<string, number> | null = null;
    if (hasProximity) {
      siteDistanceBySiteId = await this.eventsRepository.siteDistancesKmFromPoint(
        dto.nearLat!,
        dto.nearLng!,
        ordered.map((r) => r.siteId),
      );
    }

    const recurrenceRoots = [
      ...new Set(
        ordered
          .filter((r) => r.recurrenceRule != null || r.parentEventId != null)
          .map((r) => r.parentEventId ?? r.id),
      ),
    ];
    const recurrenceSeriesByRoot =
      recurrenceRoots.length > 0
        ? await this.eventsRepository.listRecurrenceSeriesEventsBatch(recurrenceRoots)
        : new Map<string, { id: string; scheduledAt: Date }[]>();

    const data = await Promise.all(
      ordered.map(async (row) => {
        const mobile = await this.mobileMapper.toMobileEvent(row, {
          siteDistanceKm: siteDistanceBySiteId?.get(row.siteId) ?? 0,
          recurrenceSeriesByRoot,
        });
        const extra = signedById.get(row.id);
        if (extra != null && extra.length > 0) {
          return { ...mobile, latestReportMediaUrls: extra };
        }
        return mobile;
      }),
    );

    return {
      data,
      meta: { hasMore: false, nextCursor: null },
      suggestions,
    };
  }
}
