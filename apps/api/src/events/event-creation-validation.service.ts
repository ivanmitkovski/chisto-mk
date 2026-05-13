import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CleanupEventStatus, EcoEventLifecycleStatus, Prisma } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { duplicateEventConflict } from '../event-schedule-conflict/duplicate-event-conflict.exception';
import { EventScheduleConflictService } from '../event-schedule-conflict/event-schedule-conflict.service';
import {
  assertEndSameSkopjeCalendarDayUtc,
  defaultEndSameSkopjeCalendarDayUtc,
} from '../common/validation/event-calendar-span.validation';
import { CreatePublicEventDto } from './dto/create-public-event.dto';
import {
  categoryFromMobile,
  difficultyFromMobile,
  normalizeGearKeys,
  scaleFromMobile,
} from './events-mobile.mapper';
import { RRule, RRuleSet, rrulestr } from 'rrule';
import { EventsRepository } from './events.repository';
import { isEventsStaff } from './events-auth.util';

@Injectable()
export class EventCreationValidationService {
  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly scheduleConflict: EventScheduleConflictService,
  ) {}

  async ensureCreatorAllowed(user: AuthenticatedUser): Promise<void> {
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
  }

  async buildUncheckedCreateInput(
    dto: CreatePublicEventDto,
    user: AuthenticatedUser,
  ): Promise<Prisma.CleanupEventUncheckedCreateInput> {
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
    return createData;
  }

  async assertSlotFree(siteId: string, scheduledAt: Date, endAt: Date | null): Promise<void> {
    const conflictSingle = await this.scheduleConflict.findConflictingEvent({
      siteId,
      scheduledAt,
      endAt,
    });
    if (conflictSingle != null) {
      throw duplicateEventConflict(conflictSingle);
    }
  }

  parseRecurrenceDates(
    dto: CreatePublicEventDto,
    parentStart: Date,
    parentEnd: Date | null,
  ): { dates: Date[]; durationMs: number } {
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
    return { dates, durationMs };
  }

  async assertSeriesSlotsFree(
    siteId: string,
    dates: Date[],
    durationMs: number,
    parentEnd: Date | null,
  ): Promise<void> {
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
  }
}
