import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { duplicateEventConflict } from '../event-schedule-conflict/duplicate-event-conflict.exception';
import { EventScheduleConflictService } from '../event-schedule-conflict/event-schedule-conflict.service';
import { CleanupEventStatus, EcoEventLifecycleStatus, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import {
  POINTS_EVENT_ORGANIZER_APPROVED,
  REASON_EVENT_ORGANIZER_APPROVED,
} from '../gamification/gamification.constants';
import { EcoEventPointsService } from '../gamification/eco-event-points.service';
import { CleanupEventRealtimeService } from '../admin-realtime/cleanup-event-realtime.service';
import { CleanupEventNotificationsService } from '../notifications/cleanup-event-notifications.service';
import { ObservabilityStore } from '../observability/observability.store';
import {
  assertEndSameSkopjeCalendarDayUtc,
} from '../common/validation/event-calendar-span.validation';
import { PatchCleanupEventDto } from './dto/patch-cleanup-event.dto';
import { CleanupEventsListService } from './cleanup-events-list.service';

@Injectable()
export class CleanupEventsPatchMutationService {
  private readonly logger = new Logger(CleanupEventsPatchMutationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly cleanupEventsSse: CleanupEventRealtimeService,
    private readonly scheduleConflict: EventScheduleConflictService,
    private readonly cleanupEventNotifications: CleanupEventNotificationsService,
    private readonly list: CleanupEventsListService,
  ) {}

  async patch(id: string, dto: PatchCleanupEventDto, actor: AuthenticatedUser) {
    const existing = await this.prisma.cleanupEvent.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOT_FOUND',
        message: 'Cleanup event not found',
      });
    }

    if (dto.status === CleanupEventStatus.DECLINED) {
      const r = dto.declineReason?.trim() ?? '';
      if (r.length < 3) {
        throw new BadRequestException({
          code: 'DECLINE_REASON_REQUIRED',
          message: 'A decline reason of at least 3 characters is required',
        });
      }
    }

    const data: {
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
    } = {};
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
    }

    const endAtPatchHasValue =
      dto.endAt !== undefined &&
      dto.endAt != null &&
      String(dto.endAt).trim() !== '';
    const isModerationStatusOnly =
      (dto.status === CleanupEventStatus.APPROVED || dto.status === CleanupEventStatus.DECLINED) &&
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

    if (dto.scheduledAt != null || dto.endAt !== undefined) {
      const conflictPatch = await this.scheduleConflict.findConflictingEvent({
        siteId: existing.siteId,
        scheduledAt: nextStart,
        endAt: nextEnd,
        excludeEventId: id,
      });
      if (conflictPatch != null) {
        throw duplicateEventConflict(conflictPatch);
      }
    }

    if (Object.keys(data).length === 0) {
      throw new BadRequestException({
        code: 'CLEANUP_PATCH_NO_CHANGES',
        message: 'No valid fields to update',
      });
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.cleanupEvent.update({
        where: { id },
        data,
      });
      if (data.status === CleanupEventStatus.APPROVED && existing.organizerId != null) {
        await this.ecoEventPoints.creditIfNew(tx, {
          userId: existing.organizerId,
          delta: POINTS_EVENT_ORGANIZER_APPROVED,
          reasonCode: REASON_EVENT_ORGANIZER_APPROVED,
          referenceType: 'CleanupEvent',
          referenceId: id,
        });
      }
    });

    const auditAction =
      data.status === CleanupEventStatus.APPROVED
        ? 'CLEANUP_EVENT_APPROVED'
        : data.status === CleanupEventStatus.DECLINED
          ? 'CLEANUP_EVENT_DECLINED'
          : 'CLEANUP_EVENT_UPDATED';
    const auditMetadata = { ...dto } as Record<string, unknown>;
    await this.audit.log({
      actorId: actor.userId,
      action: auditAction,
      resourceType: 'CleanupEvent',
      resourceId: id,
      metadata: JSON.parse(JSON.stringify(auditMetadata)) as Prisma.InputJsonValue,
    });

    const out = await this.list.findOne(id);
    this.cleanupEventsSse.emitCleanupEventUpdated(id, {
      moderationStatus: out.status,
      lifecycleStatus: out.lifecycleStatus,
    });

    const wasPending = existing.status === CleanupEventStatus.PENDING;
    const approvedNow = data.status === CleanupEventStatus.APPROVED;
    const declinedNow = data.status === CleanupEventStatus.DECLINED;

    if (wasPending && approvedNow) {
      ObservabilityStore.recordCleanupEventModerationApproved();
      const dedupeKey = String(Date.now());
      void this.cleanupEventNotifications
        .notifyAudienceEventPublished({
          eventId: id,
          siteId: out.siteId,
          title: out.title,
          organizerId: out.organizerId,
          dedupeKey,
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify audience published failed for ${id}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
      if (existing.organizerId != null) {
        void this.cleanupEventNotifications
          .notifyOrganizerApproved({
            organizerId: existing.organizerId,
            eventId: id,
            title: out.title,
          })
          .catch((err: unknown) => {
            this.logger.warn(
              `notify organizer approved failed for ${id}: ${err instanceof Error ? err.message : String(err)}`,
            );
          });
      }
    }

    if (wasPending && declinedNow && existing.organizerId != null) {
      void this.cleanupEventNotifications
        .notifyOrganizerDeclined({
          organizerId: existing.organizerId,
          eventId: id,
          title: out.title,
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify organizer declined failed for ${id}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
    }

    return out;
  }
}
