import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import {
  type CleanupEvent,
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  Prisma,
} from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { duplicateEventConflict } from '../event-schedule-conflict/duplicate-event-conflict.exception';
import { EventScheduleConflictService } from '../event-schedule-conflict/event-schedule-conflict.service';
import { PatchPublicEventDto } from './dto/patch-public-event.dto';
import {
  categoryFromMobile,
  difficultyFromMobile,
  normalizeGearKeys,
  scaleFromMobile,
} from './events-mobile.mapper';
import { PUBLIC_EVENT_MAX_END_AFTER_START_MS } from './event-schedule-policy.constants';
import { assertEndSameSkopjeCalendarDayUtc } from '../common/validation/event-calendar-span.validation';

@Injectable()
export class EventUpdateValidationService {
  constructor(private readonly scheduleConflict: EventScheduleConflictService) {}

  assertFound<T extends object>(existing: T | null | undefined): asserts existing is T {
    if (existing == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
  }

  assertOrganizer(existing: { organizerId: string | null }, user: AuthenticatedUser): void {
    if (existing.organizerId !== user.userId) {
      throw new ForbiddenException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can update this event',
      });
    }
  }

  assertLifecycleAllowsEdit(existing: { lifecycleStatus: EcoEventLifecycleStatus }): void {
    if (
      existing.lifecycleStatus === EcoEventLifecycleStatus.COMPLETED ||
      existing.lifecycleStatus === EcoEventLifecycleStatus.CANCELLED
    ) {
      throw new BadRequestException({
        code: 'EVENT_NOT_EDITABLE',
        message: 'This event can no longer be edited.',
      });
    }
  }

  async buildPatchUpdateInput(
    id: string,
    dto: PatchPublicEventDto,
    existing: CleanupEvent,
  ): Promise<Prisma.CleanupEventUpdateInput> {
    const isDeclinedResubmit = existing.status === CleanupEventStatus.DECLINED;

    const data: Prisma.CleanupEventUpdateInput = {};
    if (dto.title != null) {
      data.title = dto.title.trim();
    }
    if (dto.description != null) {
      data.description = dto.description.trim();
    }
    if (dto.category != null) {
      const c = categoryFromMobile(dto.category);
      if (c == null) {
        throw new BadRequestException({
          code: 'INVALID_EVENT_CATEGORY',
          message: 'Invalid category',
        });
      }
      data.category = c;
    }

    const nextScheduled =
      dto.scheduledAt != null ? new Date(dto.scheduledAt) : existing.scheduledAt;
    if (dto.scheduledAt != null && Number.isNaN(nextScheduled.getTime())) {
      throw new BadRequestException({
        code: 'INVALID_SCHEDULED_AT',
        message: 'Invalid scheduledAt',
      });
    }

    if (dto.scheduledAt != null) {
      data.scheduledAt = nextScheduled;
    }

    if (dto.endAt !== undefined) {
      data.endSoonNotifiedForEndAt = null;
      if (dto.endAt == null || dto.endAt === '') {
        data.endAt = null;
      } else {
        const end = new Date(dto.endAt);
        if (Number.isNaN(end.getTime()) || end.getTime() <= nextScheduled.getTime()) {
          throw new BadRequestException({
            code: 'INVALID_END_AT',
            message: 'endAt must be after scheduledAt',
          });
        }
        if (end.getTime() - nextScheduled.getTime() > PUBLIC_EVENT_MAX_END_AFTER_START_MS) {
          throw new BadRequestException({
            code: 'EVENT_END_AT_TOO_FAR',
            message: 'End time is too far from the event start.',
          });
        }
        assertEndSameSkopjeCalendarDayUtc({ scheduledAt: nextScheduled, endAt: end });
        data.endAt = end;
      }
    }

    if (
      dto.scheduledAt != null &&
      dto.endAt === undefined &&
      existing.endAt != null
    ) {
      assertEndSameSkopjeCalendarDayUtc({
        scheduledAt: nextScheduled,
        endAt: existing.endAt,
      });
    }

    if (dto.maxParticipants !== undefined) {
      data.maxParticipants = dto.maxParticipants;
    }
    if (dto.gear != null) {
      data.gear = normalizeGearKeys(dto.gear);
    }
    if (dto.scale !== undefined) {
      const s = scaleFromMobile(dto.scale);
      if (s == null) {
        throw new BadRequestException({
          code: 'INVALID_SCALE',
          message: 'Invalid scale',
        });
      }
      data.scale = s;
    }
    if (dto.difficulty !== undefined) {
      const d = difficultyFromMobile(dto.difficulty);
      if (d == null) {
        throw new BadRequestException({
          code: 'INVALID_DIFFICULTY',
          message: 'Invalid difficulty',
        });
      }
      data.difficulty = d;
    }

    if (dto.scheduledAt != null || dto.endAt !== undefined) {
      let nextEndForConflict: Date | null;
      if (dto.endAt !== undefined) {
        nextEndForConflict =
          dto.endAt == null || dto.endAt === '' ? null : new Date(dto.endAt);
      } else {
        nextEndForConflict = existing.endAt;
      }
      const conflictPatch = await this.scheduleConflict.findConflictingEvent({
        siteId: existing.siteId,
        scheduledAt: nextScheduled,
        endAt: nextEndForConflict,
        excludeEventId: id,
      });
      if (conflictPatch != null) {
        throw duplicateEventConflict(conflictPatch);
      }
    }

    if (isDeclinedResubmit) {
      data.status = CleanupEventStatus.PENDING;
    } else if (existing.status === CleanupEventStatus.APPROVED) {
      const titleChanges =
        dto.title != null && dto.title.trim() !== existing.title.trim();
      const descChanges =
        dto.description != null && dto.description.trim() !== existing.description.trim();
      let categoryChanges = false;
      if (dto.category != null) {
        const c = categoryFromMobile(dto.category);
        if (c != null && c !== existing.category) {
          categoryChanges = true;
        }
      }
      const schedChanges =
        dto.scheduledAt != null && existing.scheduledAt.getTime() !== nextScheduled.getTime();
      let endChanges = false;
      if (dto.endAt !== undefined) {
        const nextEnd = dto.endAt == null || dto.endAt === '' ? null : new Date(dto.endAt);
        endChanges =
          (existing.endAt == null) !== (nextEnd == null) ||
          (existing.endAt != null &&
            nextEnd != null &&
            existing.endAt.getTime() !== nextEnd.getTime());
      }
      const maxChanges =
        dto.maxParticipants !== undefined && dto.maxParticipants !== existing.maxParticipants;
      const gearChanges =
        dto.gear != null &&
        JSON.stringify(normalizeGearKeys(dto.gear)) !==
          JSON.stringify(normalizeGearKeys([...existing.gear]));
      let scaleChanges = false;
      if (dto.scale !== undefined) {
        const s = scaleFromMobile(dto.scale);
        if (s != null && s !== existing.scale) {
          scaleChanges = true;
        }
      }
      let diffChanges = false;
      if (dto.difficulty !== undefined) {
        const d = difficultyFromMobile(dto.difficulty);
        if (d != null && d !== existing.difficulty) {
          diffChanges = true;
        }
      }
      if (
        titleChanges ||
        descChanges ||
        categoryChanges ||
        schedChanges ||
        endChanges ||
        maxChanges ||
        gearChanges ||
        scaleChanges ||
        diffChanges
      ) {
        data.status = CleanupEventStatus.PENDING;
      }
    }

    return data;
  }
}
