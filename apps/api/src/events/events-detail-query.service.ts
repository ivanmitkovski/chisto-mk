import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { signPrivateObjectKeysDeduped } from '../storage/batch-private-object-sign';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { FindEventQueryDto } from './dto/find-event-query.dto';
import { ListEventParticipantsQueryDto } from './dto/list-event-participants-query.dto';
import { decodeParticipantCursor, encodeParticipantCursor } from './events-cursors.util';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventsTelemetryService } from './events-telemetry.service';
import { eventDetailIncludeForViewer } from './events-query.include.detail';
import { participantDisplayName, visibilityWhere } from './events-query.include.shared';
import { EventsRepository } from './events.repository';

@Injectable()
export class EventsDetailQueryService {
  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly uploads: ReportsUploadService,
    private readonly mobileMapper: EventsMobileMapperService,
    private readonly eventsTelemetry: EventsTelemetryService,
  ) {}

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
      include: eventDetailIncludeForViewer(user.userId),
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

    const avatarUrlByKey = await signPrivateObjectKeysDeduped(
      page.map((row) => row.user.avatarObjectKey),
      (key) => this.uploads.signPrivateObjectKey(key),
    );

    const data = page.map((row) => ({
      userId: row.userId,
      displayName: participantDisplayName(row.user),
      avatarUrl: row.user.avatarObjectKey
        ? (avatarUrlByKey.get(row.user.avatarObjectKey) ?? null)
        : null,
      joinedAt: row.joinedAt.toISOString(),
    }));

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
}
