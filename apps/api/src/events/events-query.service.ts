import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  Prisma,
} from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { CheckEventConflictQueryDto } from './dto/check-event-conflict-query.dto';
import { ListEventParticipantsQueryDto } from './dto/list-event-participants-query.dto';
import { FindEventQueryDto } from './dto/find-event-query.dto';
import { ListEventsQueryDto } from './dto/list-events-query.dto';
import {
  parseCategoryFilterList,
  parseLifecycleFilterList,
} from './events-mobile.mapper';
import {
  decodeCursor,
  decodeParticipantCursor,
  encodeCursor,
  encodeParticipantCursor,
} from './events-cursors.util';
import { EventScheduleConflictService } from '../event-schedule-conflict/event-schedule-conflict.service';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventsTelemetryService } from './events-telemetry.service';
import {
  assertEndSameSkopjeCalendarDayUtc,
  defaultEndSameSkopjeCalendarDayUtc,
} from '../common/validation/event-calendar-span.validation';
import {
  eventIncludeForViewer,
  participantDisplayName,
  visibilityWhere,
} from './events-query.include';
import { EventsRepository } from './events.repository';


@Injectable()
export class EventsQueryService {
  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly uploads: ReportsUploadService,
    private readonly mobileMapper: EventsMobileMapperService,
    private readonly scheduleConflict: EventScheduleConflictService,
    private readonly eventsTelemetry: EventsTelemetryService,
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

    // Full-text search: title OR description, case-insensitive.
    const searchTerm = query.q?.trim();
    const searchFilter: Prisma.CleanupEventWhereInput | null =
      searchTerm && searchTerm.length >= 2
        ? {
            OR: [
              { title: { contains: searchTerm, mode: 'insensitive' } },
              { description: { contains: searchTerm, mode: 'insensitive' } },
            ],
          }
        : null;

    // Date-range filters: inclusive, compared against scheduledAt (UTC midnight).
    const dateFromFilter: Prisma.CleanupEventWhereInput | null = query.dateFrom
      ? { scheduledAt: { gte: new Date(query.dateFrom) } }
      : null;
    const dateToFilter: Prisma.CleanupEventWhereInput | null = query.dateTo
      ? {
          scheduledAt: {
            // Include entire day by advancing to the start of the next day.
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
      include: eventIncludeForViewer(user.userId),
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

    const data = await Promise.all(
      page.map((row) =>
        this.mobileMapper.toMobileEvent(row, {
          siteDistanceKm: siteDistanceBySiteId?.get(row.siteId) ?? 0,
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

  /**
   * Minimal fields for HTTPS share landing (`GET /events/:id/share-card`).
   * Approved moderation + non-cancelled lifecycle only (no roster, no organizer PII).
   */
  async findPublicShareCard(id: string) {
    const row = await this.eventsRepository.prisma.cleanupEvent.findFirst({
      where: {
        id,
        status: CleanupEventStatus.APPROVED,
        lifecycleStatus: { not: EcoEventLifecycleStatus.CANCELLED },
      },
      select: {
        id: true,
        title: true,
        scheduledAt: true,
        endAt: true,
        lifecycleStatus: true,
        site: { select: { address: true, description: true } },
      },
    });
    if (row == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    const siteLabel = this.publicShareSiteLabel(row.site);
    return {
      id: row.id,
      title: row.title,
      siteLabel,
      scheduledAt: row.scheduledAt.toISOString(),
      endAt: row.endAt?.toISOString() ?? null,
      lifecycleStatus: row.lifecycleStatus,
    };
  }

  private publicShareSiteLabel(site: {
    address: string | null;
    description: string | null;
  }): string {
    const a = site.address?.trim();
    if (a != null && a.length > 0) {
      return a;
    }
    const d = site.description?.trim();
    if (d != null && d.length > 0) {
      return d;
    }
    return 'Site';
  }

  async findOne(id: string, user: AuthenticatedUser, geo?: FindEventQueryDto) {
    const t0 = Date.now();
    if (
      geo != null &&
      ((geo.nearLat != null && geo.nearLng == null) || (geo.nearLat == null && geo.nearLng != null))
    ) {
      throw new BadRequestException({
        code: 'EVENTS_VIEWER_GEO_INCOMPLETE',
        message: 'nearLat and nearLng must both be provided',
      });
    }
    const row = await this.eventsRepository.prisma.cleanupEvent.findFirst({
      where: {
        id,
        ...visibilityWhere(user.userId),
      },
      include: eventIncludeForViewer(user.userId),
    });
    if (row == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    let siteDistanceKm = 0;
    if (geo?.hasViewerGeo()) {
      const bySite = await this.eventsRepository.siteDistancesKmFromPoint(
        geo.nearLat!,
        geo.nearLng!,
        [row.siteId],
      );
      siteDistanceKm = bySite.get(row.siteId) ?? 0;
    }
    const payload = await this.mobileMapper.toMobileEvent(row, { siteDistanceKm });
    this.eventsTelemetry.emitSpan('events.find_one', {
      duration_ms: Date.now() - t0,
    });
    return payload;
  }

  /**
   * Paginated joiners for an event (organizer is not an EventParticipant row).
   * Ordered by joinedAt ascending, then id ascending.
   */
  async listParticipants(
    id: string,
    user: AuthenticatedUser,
    query: ListEventParticipantsQueryDto,
  ) {
    const t0 = Date.now();
    const visible = await this.eventsRepository.prisma.cleanupEvent.findFirst({
      where: {
        id,
        ...visibilityWhere(user.userId),
      },
      select: { id: true },
    });
    if (visible == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    const limit = query.getLimit();
    let cursorClause: Prisma.EventParticipantWhereInput = {};
    if (query.cursor != null && query.cursor.trim() !== '') {
      const { joinedAt, participantId } = decodeParticipantCursor(query.cursor.trim());
      cursorClause = {
        OR: [
          { joinedAt: { gt: joinedAt } },
          { AND: [{ joinedAt }, { id: { gt: participantId } }] },
        ],
      };
    }

    const rows = await this.eventsRepository.prisma.eventParticipant.findMany({
      where: {
        eventId: id,
        ...cursorClause,
      },
      orderBy: [{ joinedAt: 'asc' }, { id: 'asc' }],
      take: limit + 1,
      select: {
        id: true,
        joinedAt: true,
        userId: true,
        user: {
          select: { firstName: true, lastName: true, avatarObjectKey: true },
        },
      },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const last = page[page.length - 1];
    const nextCursor =
      hasMore && last != null ? encodeParticipantCursor(last.joinedAt, last.id) : null;

    const data = await Promise.all(
      page.map(async (row) => ({
        userId: row.userId,
        displayName: participantDisplayName(row.user),
        avatarUrl: await this.uploads.signPrivateObjectKey(row.user.avatarObjectKey),
        joinedAt: row.joinedAt.toISOString(),
      })),
    );

    this.eventsTelemetry.emitSpan('events.list_participants', {
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

  /**
   * Read-only preview for create/edit forms; does not return 409.
   */
  async checkScheduleConflictPreview(query: CheckEventConflictQueryDto): Promise<{
    hasConflict: boolean;
    conflictingEvent?: { id: string; title: string; scheduledAt: string };
  }> {
    const scheduledAt = new Date(query.scheduledAt);
    if (Number.isNaN(scheduledAt.getTime())) {
      throw new BadRequestException({
        code: 'INVALID_SCHEDULED_AT',
        message: 'Invalid scheduledAt',
      });
    }
    let endAt: Date | null = null;
    if (query.endAt != null && query.endAt.trim() !== '') {
      endAt = new Date(query.endAt);
      if (Number.isNaN(endAt.getTime()) || endAt.getTime() <= scheduledAt.getTime()) {
        throw new BadRequestException({
          code: 'INVALID_END_AT',
          message: 'endAt must be after scheduledAt',
        });
      }
      assertEndSameSkopjeCalendarDayUtc({ scheduledAt, endAt });
    } else {
      endAt = defaultEndSameSkopjeCalendarDayUtc(scheduledAt);
    }
    const row = await this.scheduleConflict.findConflictingEvent({
      siteId: query.siteId,
      scheduledAt,
      endAt,
      ...(query.excludeEventId != null && query.excludeEventId !== ''
        ? { excludeEventId: query.excludeEventId }
        : {}),
    });
    if (row == null) {
      return { hasConflict: false };
    }
    return {
      hasConflict: true,
      conflictingEvent: {
        id: row.id,
        title: row.title,
        scheduledAt: row.scheduledAt.toISOString(),
      },
    };
  }
}
