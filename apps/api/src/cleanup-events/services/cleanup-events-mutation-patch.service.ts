import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { duplicateEventConflict } from '../../event-schedule-conflict/util/duplicate-event-conflict.exception';
import { EventScheduleConflictService } from '../../event-schedule-conflict/services/event-schedule-conflict.service';
import { CleanupEventStatus, Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import {
  POINTS_EVENT_ORGANIZER_APPROVED,
  REASON_EVENT_ORGANIZER_APPROVED,
} from '../../gamification/constants/gamification.constants';
import { EcoEventPointsService, type EcoEventPointsCreditResult } from '../../gamification/services/eco-event-points.service';
import { emitGamificationPointsCredited } from '../../gamification/util/gamification-credit-events.util';
import { CleanupEventRealtimeService } from '../../admin-realtime/services/cleanup-event-realtime.service';
import { CleanupEventNotificationsService } from '../../notifications/services/cleanup-event-notifications.service';
import { ObservabilityStore } from '../../observability/observability.store';
import { PatchCleanupEventDto } from '../dto/patch-cleanup-event.dto';
import { buildCleanupEventPatchData } from '../util/cleanup-event-patch-data.util';
import { CleanupEventsListService } from '../services/cleanup-events-list.service';

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
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async patch(id: string, dto: PatchCleanupEventDto, actor: AuthenticatedUser) {
    const existing = await this.prisma.cleanupEvent.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOT_FOUND',
        message: 'Cleanup event not found',
      });
    }

    const { data, nextStart, nextEnd } = buildCleanupEventPatchData({
      dto,
      existing,
      actorUserId: actor.userId,
    });

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

    const organizerCredit: EcoEventPointsCreditResult | null = await this.prisma.$transaction(
      async (tx) => {
        await tx.cleanupEvent.update({
          where: { id },
          data,
        });
        if (data.status === CleanupEventStatus.APPROVED && existing.organizerId != null) {
          return this.ecoEventPoints.creditIfNew(tx, {
            userId: existing.organizerId,
            delta: POINTS_EVENT_ORGANIZER_APPROVED,
            reasonCode: REASON_EVENT_ORGANIZER_APPROVED,
            referenceType: 'CleanupEvent',
            referenceId: id,
          });
        }
        return null;
      },
    );
    if (organizerCredit != null && organizerCredit.granted > 0 && existing.organizerId != null) {
      emitGamificationPointsCredited(this.eventEmitter, existing.organizerId, organizerCredit);
    }

    const auditAction =
      data.status === CleanupEventStatus.APPROVED
        ? 'CLEANUP_EVENT_APPROVED'
        : data.status === CleanupEventStatus.DECLINED
          ? 'CLEANUP_EVENT_DECLINED'
          : data.status === CleanupEventStatus.PENDING
            ? 'CLEANUP_EVENT_RETURNED_TO_PENDING'
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
    const returnedToPendingNow = data.status === CleanupEventStatus.PENDING;

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
      const trimmedDeclineReason = dto.declineReason?.trim() ?? '';
      void this.cleanupEventNotifications
        .notifyOrganizerDeclined({
          organizerId: existing.organizerId,
          eventId: id,
          title: out.title,
          ...(trimmedDeclineReason.length > 0 ? { declineReason: trimmedDeclineReason } : {}),
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify organizer declined failed for ${id}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
    }

    if (returnedToPendingNow && existing.organizerId != null) {
      void this.cleanupEventNotifications
        .notifyOrganizerReturnedToPending({
          organizerId: existing.organizerId,
          eventId: id,
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify organizer returned to pending failed for ${id}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
    }

    return out;
  }
}
