import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { duplicateEventConflict } from '../event-schedule-conflict/duplicate-event-conflict.exception';
import { EventScheduleConflictService } from '../event-schedule-conflict/event-schedule-conflict.service';
import { CleanupEventStatus, EcoEventLifecycleStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import { CleanupEventRealtimeService } from '../admin-realtime/cleanup-event-realtime.service';
import { CleanupEventNotificationsService } from '../notifications/cleanup-event-notifications.service';
import {
  assertEndSameSkopjeCalendarDayUtc,
  defaultEndSameSkopjeCalendarDayUtc,
} from '../common/validation/event-calendar-span.validation';
import { CreateCleanupEventDto } from './dto/create-cleanup-event.dto';
import { CleanupEventsListService } from './cleanup-events-list.service';

@Injectable()
export class CleanupEventsCreateMutationService {
  private readonly logger = new Logger(CleanupEventsCreateMutationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly cleanupEventsSse: CleanupEventRealtimeService,
    private readonly scheduleConflict: EventScheduleConflictService,
    private readonly cleanupEventNotifications: CleanupEventNotificationsService,
    private readonly list: CleanupEventsListService,
  ) {}

  async create(dto: CreateCleanupEventDto, actor: AuthenticatedUser) {
    const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: 'Site not found',
      });
    }

    const status = dto.status ?? CleanupEventStatus.APPROVED;
    const completedAt = dto.completedAt ? new Date(dto.completedAt) : null;
    const lifecycleStatus =
      completedAt != null ? EcoEventLifecycleStatus.COMPLETED : EcoEventLifecycleStatus.UPCOMING;
    const title = dto.title?.trim() || 'Cleanup event';
    const description = dto.description?.trim() ?? '';
    const recurrenceRule =
      dto.recurrenceRule != null && dto.recurrenceRule.trim() !== ''
        ? dto.recurrenceRule.trim()
        : null;
    const scheduledAtDate = new Date(dto.scheduledAt);
    if (Number.isNaN(scheduledAtDate.getTime())) {
      throw new BadRequestException({
        code: 'INVALID_SCHEDULED_AT',
        message: 'Invalid scheduledAt',
      });
    }
    let endAtDate: Date;
    if (dto.endAt != null && dto.endAt.trim() !== '') {
      endAtDate = new Date(dto.endAt);
      if (Number.isNaN(endAtDate.getTime()) || endAtDate.getTime() <= scheduledAtDate.getTime()) {
        throw new BadRequestException({
          code: 'INVALID_END_AT',
          message: 'endAt must be after scheduledAt',
        });
      }
    } else {
      endAtDate = defaultEndSameSkopjeCalendarDayUtc(scheduledAtDate);
    }
    assertEndSameSkopjeCalendarDayUtc({ scheduledAt: scheduledAtDate, endAt: endAtDate });
    const conflict = await this.scheduleConflict.findConflictingEvent({
      siteId: dto.siteId,
      scheduledAt: scheduledAtDate,
      endAt: endAtDate,
    });
    if (conflict != null) {
      throw duplicateEventConflict(conflict);
    }
    const e = await this.prisma.cleanupEvent.create({
      data: {
        siteId: dto.siteId,
        scheduledAt: scheduledAtDate,
        endAt: endAtDate,
        completedAt,
        title,
        description,
        organizerId: dto.organizerId ?? null,
        participantCount: dto.participantCount ?? 0,
        status,
        lifecycleStatus,
        recurrenceRule,
      },
    });

    await this.audit.log({
      actorId: actor.userId,
      action: 'CLEANUP_EVENT_CREATED',
      resourceType: 'CleanupEvent',
      resourceId: e.id,
    });

    const out = await this.list.findOne(e.id);
    if (status === CleanupEventStatus.PENDING) {
      this.cleanupEventsSse.emitCleanupEventPending(e.id);
      void this.cleanupEventNotifications
        .notifyStaffPendingReview({
          eventId: e.id,
          siteId: dto.siteId,
          title,
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify staff pending failed for ${e.id}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
    } else {
      this.cleanupEventsSse.emitCleanupEventCreated(e.id, {
        moderationStatus: status,
        lifecycleStatus,
      });
      const dedupeKey = String(Date.now());
      void this.cleanupEventNotifications
        .notifyAudienceEventPublished({
          eventId: e.id,
          siteId: dto.siteId,
          title,
          organizerId: dto.organizerId ?? null,
          dedupeKey,
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify audience published failed for ${e.id}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
    }
    return out;
  }
}
