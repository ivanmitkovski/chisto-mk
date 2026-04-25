import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  Prisma,
} from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CleanupEventsEventsService } from '../admin-events/cleanup-events-events.service';
import { duplicateEventConflict } from '../event-schedule-conflict/duplicate-event-conflict.exception';
import { EventScheduleConflictService } from '../event-schedule-conflict/event-schedule-conflict.service';
import { CleanupEventNotificationsService } from '../notifications/cleanup-event-notifications.service';
import {
  assertEndSameSkopjeCalendarDayUtc,
  defaultEndSameSkopjeCalendarDayUtc,
} from '../common/validation/event-calendar-span.validation';
import { CreatePublicEventDto } from './dto/create-public-event.dto';
import { EventMobileResponseDto } from './dto/event-mobile-response.dto';
import {
  categoryFromMobile,
  difficultyFromMobile,
  normalizeGearKeys,
  scaleFromMobile,
} from './events-mobile.mapper';
import { RRule, RRuleSet, rrulestr } from 'rrule';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventRouteSegmentsService } from './event-route-segments.service';
import { eventIncludeForViewer } from './events-query.include';
import { EventsRepository } from './events.repository';
import { isEventsStaff } from './events-auth.util';


@Injectable()
export class EventsCreationService {
  private readonly logger = new Logger(EventsCreationService.name);

  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly mobileMapper: EventsMobileMapperService,
    private readonly cleanupEventsSse: CleanupEventsEventsService,
    private readonly cleanupEventNotifications: CleanupEventNotificationsService,
    private readonly scheduleConflict: EventScheduleConflictService,
    private readonly routeSegments: EventRouteSegmentsService,
  ) {}

  async create(dto: CreatePublicEventDto, user: AuthenticatedUser) {
    if (!isEventsStaff(user)) {
      const creator = await this.eventsRepository.prisma.user.findUnique({
        where: { id: user.userId },
        select: { organizerCertifiedAt: true },
      });
      if (creator?.organizerCertifiedAt == null) {
        throw new ForbiddenException({
          code: 'EVENTS_ORGANIZER_NOT_CERTIFIED',
          message:
            'Complete the organizer toolkit before creating your first event.',
        });
      }
    }

    const category = categoryFromMobile(dto.category);
    if (category == null) {
      throw new BadRequestException({
        code: 'INVALID_EVENT_CATEGORY',
        message: 'Invalid category',
      });
    }
    const scheduledAt = new Date(dto.scheduledAt);
    if (Number.isNaN(scheduledAt.getTime())) {
      throw new BadRequestException({
        code: 'INVALID_SCHEDULED_AT',
        message: 'Invalid scheduledAt',
      });
    }
    let endAt: Date;
    if (dto.endAt != null && dto.endAt.trim() !== '') {
      endAt = new Date(dto.endAt);
      if (Number.isNaN(endAt.getTime()) || endAt.getTime() <= scheduledAt.getTime()) {
        throw new BadRequestException({
          code: 'INVALID_END_AT',
          message: 'endAt must be after scheduledAt',
        });
      }
    } else {
      endAt = defaultEndSameSkopjeCalendarDayUtc(scheduledAt);
    }
    assertEndSameSkopjeCalendarDayUtc({ scheduledAt, endAt });

    const site = await this.eventsRepository.prisma.site.findUnique({ where: { id: dto.siteId } });
    if (site == null) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: 'Site not found',
      });
    }

    const scale = scaleFromMobile(dto.scale);
    const difficulty = difficultyFromMobile(dto.difficulty);
    const gear = normalizeGearKeys(dto.gear);
    const moderation = isEventsStaff(user) ? CleanupEventStatus.APPROVED : CleanupEventStatus.PENDING;

    const createData: Prisma.CleanupEventUncheckedCreateInput = {
      siteId: dto.siteId,
      title: dto.title.trim(),
      description: dto.description.trim(),
      category,
      scheduledAt,
      endAt,
      organizerId: user.userId,
      status: moderation,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      participantCount: 0,
      maxParticipants: dto.maxParticipants ?? null,
      gear,
    };
    if (scale != null) {
      createData.scale = scale;
    }
    if (difficulty != null) {
      createData.difficulty = difficulty;
    }

    // If a recurrence rule is provided, build the full series before returning the parent.
    if (dto.recurrenceRule != null && dto.recurrenceRule.trim() !== '') {
      return this.createSeries(dto, createData, user, scheduledAt, endAt);
    }

    const conflictSingle = await this.scheduleConflict.findConflictingEvent({
      siteId: dto.siteId,
      scheduledAt,
      endAt,
    });
    if (conflictSingle != null) {
      throw duplicateEventConflict(conflictSingle);
    }

    const created = await this.eventsRepository.prisma.cleanupEvent.create({
      data: createData,
    });

    if (dto.routeWaypoints != null && dto.routeWaypoints.length > 0) {
      await this.routeSegments.replaceWaypoints(created.id, user, dto.routeWaypoints);
    }

    if (moderation === CleanupEventStatus.PENDING) {
      this.cleanupEventsSse.emitCleanupEventPending(created.id);
      void this.cleanupEventNotifications
        .notifyStaffPendingReview({
          eventId: created.id,
          siteId: dto.siteId,
          title: dto.title.trim(),
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify staff pending failed for ${created.id}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
    } else {
      this.cleanupEventsSse.emitCleanupEventCreated(created.id, {
        moderationStatus: moderation,
        lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      });
      void this.cleanupEventNotifications
        .notifyAudienceEventPublished({
          eventId: created.id,
          siteId: dto.siteId,
          title: dto.title.trim(),
          organizerId: user.userId,
          dedupeKey: String(Date.now()),
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify audience published failed for ${created.id}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
    }

    const row = await this.eventsRepository.prisma.cleanupEvent.findFirstOrThrow({
      where: { id: created.id },
      include: eventIncludeForViewer(user.userId),
    });

    return this.mobileMapper.toMobileEvent(row);
  }

  /**
   * Creates a recurring series of [CleanupEvent] rows inside a Prisma transaction.
   * The first event is the "parent" (recurrenceIndex = 0); subsequent events reference it
   * via parentEventId. Capped at 52 occurrences regardless of the RRULE COUNT/UNTIL.
   */
  private async createSeries(
    dto: CreatePublicEventDto,
    baseData: Prisma.CleanupEventUncheckedCreateInput,
    user: AuthenticatedUser,
    parentStart: Date,
    parentEnd: Date | null,
  ) {
    const count = Math.min(dto.recurrenceCount ?? 4, 52);
    let dates: Date[];
    try {
      const rrulePart = dto.recurrenceRule!.startsWith('RRULE:')
        ? dto.recurrenceRule!
        : `RRULE:${dto.recurrenceRule}`;
      const y = parentStart.getUTCFullYear();
      const mo = String(parentStart.getUTCMonth() + 1).padStart(2, '0');
      const da = String(parentStart.getUTCDate()).padStart(2, '0');
      const hh = String(parentStart.getUTCHours()).padStart(2, '0');
      const mm = String(parentStart.getUTCMinutes()).padStart(2, '0');
      const ss = String(parentStart.getUTCSeconds()).padStart(2, '0');
      const dtstart = `${y}${mo}${da}T${hh}${mm}${ss}Z`;
      const fullIcs = `DTSTART:${dtstart}\n${rrulePart}`;
      const parsed = rrulestr(fullIcs);
      const rule = parsed instanceof RRule ? parsed : (parsed as RRuleSet).rrules()[0];
      if (!rule) {
        dates = [parentStart];
      } else {
        dates = rule.all((_, len) => len < count);
      }
      if (dates.length === 0) {
        dates = [parentStart];
      }
    } catch {
      throw new BadRequestException({
        code: 'INVALID_RECURRENCE_RULE',
        message: 'Could not parse recurrenceRule as a valid RFC 5545 RRULE',
      });
    }

    const durationMs = parentEnd != null ? parentEnd.getTime() - parentStart.getTime() : 0;

    const siteId = baseData.siteId as string;
    for (const d of dates) {
      const occEnd =
        durationMs > 0 ? new Date(d.getTime() + durationMs) : parentEnd;
      const conflictOcc = await this.scheduleConflict.findConflictingEvent({
        siteId,
        scheduledAt: d,
        endAt: occEnd,
      });
      if (conflictOcc != null) {
        throw duplicateEventConflict(conflictOcc);
      }
    }

    const mobileEvent = await this.eventsRepository.prisma.$transaction(async (tx) => {
      // Create the parent event (index 0).
      const parent = await tx.cleanupEvent.create({
        data: {
          ...baseData,
          scheduledAt: dates[0],
          endAt: durationMs > 0 ? new Date(dates[0].getTime() + durationMs) : parentEnd,
          recurrenceRule: dto.recurrenceRule ?? null,
          recurrenceIndex: 0,
        },
      });

      // Create the child events in bulk.
      if (dates.length > 1) {
        await tx.cleanupEvent.createMany({
          data: dates.slice(1).map((d, i) => ({
            ...baseData,
            scheduledAt: d,
            endAt: durationMs > 0 ? new Date(d.getTime() + durationMs) : null,
            parentEventId: parent.id,
            recurrenceRule: dto.recurrenceRule ?? null,
            recurrenceIndex: i + 1,
          })),
        });
      }

      const row = await tx.cleanupEvent.findFirstOrThrow({
        where: { id: parent.id },
        include: eventIncludeForViewer(user.userId),
      });

      return this.mobileMapper.toMobileEvent(row);
    });

    const parentId = mobileEvent.id;
    let seriesMobile: EventMobileResponseDto = mobileEvent;
    if (dto.routeWaypoints != null && dto.routeWaypoints.length > 0 && parentId.length > 0) {
      await this.routeSegments.replaceWaypoints(parentId, user, dto.routeWaypoints);
      const rowWithRoute = await this.eventsRepository.prisma.cleanupEvent.findFirstOrThrow({
        where: { id: parentId },
        include: eventIncludeForViewer(user.userId),
      });
      seriesMobile = await this.mobileMapper.toMobileEvent(rowWithRoute);
    }
    if (parentId.length > 0) {
      if (baseData.status === CleanupEventStatus.PENDING) {
        this.cleanupEventsSse.emitCleanupEventPending(parentId);
        void this.cleanupEventNotifications
          .notifyStaffPendingReview({
            eventId: parentId,
            siteId,
            title: dto.title.trim(),
          })
          .catch((err: unknown) => {
            this.logger.warn(
              `notify staff pending failed for series ${parentId}: ${err instanceof Error ? err.message : String(err)}`,
            );
          });
      } else {
        this.cleanupEventsSse.emitCleanupEventCreated(parentId, {
          moderationStatus: String(baseData.status),
          lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
        });
        void this.cleanupEventNotifications
          .notifyAudienceEventPublished({
            eventId: parentId,
            siteId,
            title: dto.title.trim(),
            organizerId: user.userId,
            dedupeKey: String(Date.now()),
          })
          .catch((err: unknown) => {
            this.logger.warn(
              `notify audience published failed for series ${parentId}: ${err instanceof Error ? err.message : String(err)}`,
            );
          });
      }
    }

    return seriesMobile;
  }
}
