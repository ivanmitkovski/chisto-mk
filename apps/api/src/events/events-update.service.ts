import { Injectable, Logger } from '@nestjs/common';
import { CleanupEventStatus } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CleanupEventRealtimeService } from '../admin-realtime/cleanup-event-realtime.service';
import { CleanupEventNotificationsService } from '../notifications/cleanup-event-notifications.service';
import { EventChatMutationsService } from '../event-chat/event-chat-mutations.service';
import { PatchPublicEventDto } from './dto/patch-public-event.dto';
import { EventUpdateValidationService } from './event-update-validation.service';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventRouteSegmentsService } from './event-route-segments.service';
import { eventDetailIncludeForViewer } from './events-query.include.detail';
import { EventsRepository } from './events.repository';

@Injectable()
export class EventsUpdateService {
  private readonly logger = new Logger(EventsUpdateService.name);

  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly mobileMapper: EventsMobileMapperService,
    private readonly patchValidation: EventUpdateValidationService,
    private readonly cleanupEventsSse: CleanupEventRealtimeService,
    private readonly cleanupEventNotifications: CleanupEventNotificationsService,
    private readonly eventChatMutations: EventChatMutationsService,
    private readonly routeSegments: EventRouteSegmentsService,
  ) {}

  async patchEvent(id: string, dto: PatchPublicEventDto, user: AuthenticatedUser) {
    const existing = await this.eventsRepository.prisma.cleanupEvent.findUnique({
      where: { id },
      include: eventDetailIncludeForViewer(user.userId),
    });
    this.patchValidation.assertFound(existing);
    this.patchValidation.assertOrganizer(existing, user);
    this.patchValidation.assertLifecycleAllowsEdit(existing);

    const data = await this.patchValidation.buildPatchUpdateInput(id, dto, existing);

    const updated = await this.eventsRepository.prisma.cleanupEvent.update({
      where: { id },
      data,
      include: eventDetailIncludeForViewer(user.userId),
    });

    const returnedToPendingForReview =
      updated.status === CleanupEventStatus.PENDING &&
      (existing.status === CleanupEventStatus.APPROVED ||
        existing.status === CleanupEventStatus.DECLINED);
    if (returnedToPendingForReview) {
      this.cleanupEventsSse.emitCleanupEventPending(id);
      void this.cleanupEventNotifications
        .notifyStaffPendingReview({
          eventId: id,
          siteId: updated.siteId,
          title: updated.title,
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify staff re-review failed for ${id}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
      if (updated.organizerId != null) {
        void this.cleanupEventNotifications
          .notifyOrganizerReturnedToPending({
            organizerId: updated.organizerId,
            eventId: id,
          })
          .catch((err: unknown) => {
            this.logger.warn(
              `notify organizer re-review failed for ${id}: ${err instanceof Error ? err.message : String(err)}`,
            );
          });
      }
    }

    const scheduleChanged =
      dto.scheduledAt != null &&
      existing.scheduledAt.getTime() !== updated.scheduledAt.getTime();
    const endChanged =
      dto.endAt !== undefined &&
      ((existing.endAt == null) !== (updated.endAt == null) ||
        (existing.endAt != null &&
          updated.endAt != null &&
          existing.endAt.getTime() !== updated.endAt.getTime()));
    const titleChanged =
      dto.title != null && existing.title.trim() !== updated.title.trim();
    const descriptionChanged =
      dto.description != null && existing.description.trim() !== updated.description.trim();
    if (scheduleChanged || endChanged || titleChanged || descriptionChanged) {
      void this.eventChatMutations
        .createSystemMessage({
          eventId: id,
          authorId: user.userId,
          body: 'Event details were updated',
          systemPayload: { action: 'event_updated', updatedByUserId: user.userId },
        })
        .catch((err: unknown) => {
          this.logger.warn(`Event chat system message (patch) failed: ${String(err)}`);
        });
    }

    if (dto.routeWaypoints !== undefined) {
      await this.routeSegments.replaceWaypoints(id, user, dto.routeWaypoints);
      const refreshed = await this.eventsRepository.prisma.cleanupEvent.findFirstOrThrow({
        where: { id },
        include: eventDetailIncludeForViewer(user.userId),
      });
      return await this.mobileMapper.toMobileEvent(refreshed);
    }

    return await this.mobileMapper.toMobileEvent(updated);
  }
}
