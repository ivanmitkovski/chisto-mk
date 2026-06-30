import { BadRequestException } from '@nestjs/common';
import { CleanupEventStatus, EcoEventLifecycleStatus } from '../../prisma-client';
import {
  assertEndSameSkopjeCalendarDayUtc,
} from '../../common/validation/event-calendar-span.validation';
import { PatchCleanupEventDto } from '../dto/patch-cleanup-event.dto';

export type CleanupEventPatchData = {
  title?: string;
  description?: string;
  recurrenceRule?: string | null;
  scheduledAt?: Date;
  endAt?: Date | null;
  endSoonNotifiedForEndAt?: Date | null;
  completedAt?: Date | null;
  participantCount?: number;
  status?: CleanupEventStatus;
  lifecycleStatus?: EcoEventLifecycleStatus;
  moderatedById?: string | null;
  moderatedAt?: Date | null;
  declineReason?: string | null;
};

type ExistingCleanupEvent = {
  scheduledAt: Date;
  endAt: Date | null;
  status: CleanupEventStatus;
  lifecycleStatus: EcoEventLifecycleStatus;
};

/**
 * Validates a cleanup-event PATCH dto against the existing row and maps it to
 * a prisma update payload. Throws BadRequestException on invalid transitions,
 * dates, or missing decline reasons.
 */
export function buildCleanupEventPatchData(args: {
  dto: PatchCleanupEventDto;
  existing: ExistingCleanupEvent;
  actorUserId: string;
}): { data: CleanupEventPatchData; nextStart: Date; nextEnd: Date | null } {
  const { dto, existing, actorUserId } = args;

  if (dto.status === CleanupEventStatus.DECLINED) {
    const r = dto.declineReason?.trim() ?? '';
    if (r.length < 3) {
      throw new BadRequestException({
        code: 'DECLINE_REASON_REQUIRED',
        message: 'A decline reason of at least 3 characters is required',
      });
    }
  }

  const data: CleanupEventPatchData = {};
  if (dto.title != null) {
    data.title = dto.title.trim() || 'Cleanup event';
  }
  if (dto.description != null) {
    data.description = dto.description.trim();
  }
  if (dto.recurrenceRule !== undefined) {
    const t = dto.recurrenceRule.trim();
    data.recurrenceRule = t.length > 0 ? t : null;
  }
  if (dto.scheduledAt != null) {
    data.scheduledAt = new Date(dto.scheduledAt);
  }
  if (dto.completedAt !== undefined) {
    data.completedAt = dto.completedAt ? new Date(dto.completedAt) : null;
    data.lifecycleStatus = dto.completedAt
      ? EcoEventLifecycleStatus.COMPLETED
      : EcoEventLifecycleStatus.UPCOMING;
  }
  if (dto.participantCount != null) {
    data.participantCount = dto.participantCount;
  }
  if (dto.lifecycleStatus != null) {
    if (existing.lifecycleStatus === EcoEventLifecycleStatus.COMPLETED) {
      throw new BadRequestException({
        code: 'INVALID_LIFECYCLE_TRANSITION',
        message: 'Cannot change lifecycle of a completed event',
      });
    }
    if (
      existing.lifecycleStatus === EcoEventLifecycleStatus.CANCELLED &&
      dto.lifecycleStatus !== EcoEventLifecycleStatus.CANCELLED
    ) {
      throw new BadRequestException({
        code: 'INVALID_LIFECYCLE_TRANSITION',
        message: 'Cannot reopen a cancelled event',
      });
    }
    data.lifecycleStatus = dto.lifecycleStatus;
    if (dto.lifecycleStatus === EcoEventLifecycleStatus.COMPLETED) {
      data.completedAt =
        dto.completedAt != null && String(dto.completedAt).trim() !== ''
          ? new Date(dto.completedAt as string)
          : new Date();
    }
  }
  if (dto.status === CleanupEventStatus.APPROVED || dto.status === CleanupEventStatus.DECLINED) {
    if (existing.status !== CleanupEventStatus.PENDING) {
      throw new BadRequestException({
        code: 'EVENT_NOT_PENDING',
        message: 'Only PENDING events can be approved or declined',
      });
    }
    data.status = dto.status;
    data.moderatedById = actorUserId;
    data.moderatedAt = new Date();
    if (dto.status === CleanupEventStatus.DECLINED) {
      data.declineReason = dto.declineReason?.trim() ?? null;
    } else {
      data.declineReason = null;
    }
  } else if (dto.status === CleanupEventStatus.PENDING) {
    if (
      existing.status !== CleanupEventStatus.APPROVED &&
      existing.status !== CleanupEventStatus.DECLINED
    ) {
      throw new BadRequestException({
        code: 'EVENT_NOT_MODERATED',
        message: 'Only APPROVED or DECLINED events can be returned to pending',
      });
    }
    data.status = CleanupEventStatus.PENDING;
    data.moderatedById = null;
    data.moderatedAt = null;
    data.declineReason = null;
  }

  const endAtPatchHasValue =
    dto.endAt !== undefined &&
    dto.endAt != null &&
    String(dto.endAt).trim() !== '';
  const isModerationStatusOnly =
    (dto.status === CleanupEventStatus.APPROVED ||
      dto.status === CleanupEventStatus.DECLINED ||
      dto.status === CleanupEventStatus.PENDING) &&
    dto.scheduledAt == null &&
    !endAtPatchHasValue;

  const nextStart =
    dto.scheduledAt != null ? new Date(dto.scheduledAt) : existing.scheduledAt;
  if (dto.scheduledAt != null && Number.isNaN(nextStart.getTime())) {
    throw new BadRequestException({
      code: 'INVALID_SCHEDULED_AT',
      message: 'Invalid scheduledAt',
    });
  }

  let nextEnd: Date | null = existing.endAt;
  if (dto.endAt !== undefined) {
    if (dto.endAt == null || String(dto.endAt).trim() === '') {
      nextEnd = null;
      data.endAt = null;
      data.endSoonNotifiedForEndAt = null;
    } else {
      const parsedEnd = new Date(dto.endAt);
      if (Number.isNaN(parsedEnd.getTime())) {
        throw new BadRequestException({
          code: 'INVALID_END_AT',
          message: 'Invalid endAt',
        });
      }
      nextEnd = parsedEnd;
      data.endAt = parsedEnd;
      data.endSoonNotifiedForEndAt = null;
    }
  }

  if (nextEnd != null && !isModerationStatusOnly) {
    if (nextEnd.getTime() <= nextStart.getTime()) {
      throw new BadRequestException({
        code: 'INVALID_END_AT',
        message: 'endAt must be after scheduledAt',
      });
    }
    assertEndSameSkopjeCalendarDayUtc({ scheduledAt: nextStart, endAt: nextEnd });
  }

  if (
    !isModerationStatusOnly &&
    dto.scheduledAt != null &&
    dto.endAt === undefined &&
    existing.endAt != null
  ) {
    assertEndSameSkopjeCalendarDayUtc({
      scheduledAt: nextStart,
      endAt: existing.endAt,
    });
  }

  return { data, nextStart, nextEnd };
}
