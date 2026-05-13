import { Injectable, Logger } from '@nestjs/common';
import { CleanupEventStatus, EcoEventLifecycleStatus, Prisma } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CleanupEventRealtimeService } from '../admin-realtime/cleanup-event-realtime.service';
import { CleanupEventNotificationsService } from '../notifications/cleanup-event-notifications.service';
import { CreatePublicEventDto } from './dto/create-public-event.dto';
import type { EventMobileResponseDto } from './dto/event-mobile-response.dto';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventRouteSegmentsService } from './event-route-segments.service';
import { eventDetailIncludeForViewer } from './events-query.include.detail';
import { EventsRepository } from './events.repository';

@Injectable()
export class EventCreationPersistenceService {
  private readonly logger = new Logger(EventCreationPersistenceService.name);

  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly mobileMapper: EventsMobileMapperService,
    private readonly cleanupEventsSse: CleanupEventRealtimeService,
    private readonly cleanupEventNotifications: CleanupEventNotificationsService,
    private readonly routeSegments: EventRouteSegmentsService,
  ) {}

  private emitPostCreate(
    createdId: string,
    dto: CreatePublicEventDto,
    user: AuthenticatedUser,
    moderation: CleanupEventStatus,
  ): void {
    if (moderation === CleanupEventStatus.PENDING) {
      this.cleanupEventsSse.emitCleanupEventPending(createdId);
      void this.cleanupEventNotifications
        .notifyStaffPendingReview({
          eventId: createdId,
          siteId: dto.siteId,
          title: dto.title.trim(),
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify staff pending failed for ${createdId}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
    } else {
      this.cleanupEventsSse.emitCleanupEventCreated(createdId, {
        moderationStatus: moderation,
        lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      });
      void this.cleanupEventNotifications
        .notifyAudienceEventPublished({
          eventId: createdId,
          siteId: dto.siteId,
          title: dto.title.trim(),
          organizerId: user.userId,
          dedupeKey: String(Date.now()),
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `notify audience published failed for ${createdId}: ${err instanceof Error ? err.message : String(err)}`,
          );
        });
    }
  }

  async createSingle(
    createData: Prisma.CleanupEventUncheckedCreateInput,
    dto: CreatePublicEventDto,
    user: AuthenticatedUser,
    moderation: CleanupEventStatus,
  ): Promise<EventMobileResponseDto> {
    const created = await this.eventsRepository.prisma.cleanupEvent.create({
      data: createData,
    });

    if (dto.routeWaypoints != null && dto.routeWaypoints.length > 0) {
      await this.routeSegments.replaceWaypoints(created.id, user, dto.routeWaypoints);
    }

    this.emitPostCreate(created.id, dto, user, moderation);

    const row = await this.eventsRepository.prisma.cleanupEvent.findFirstOrThrow({
      where: { id: created.id },
      include: eventDetailIncludeForViewer(user.userId),
    });

    return await this.mobileMapper.toMobileEvent(row);
  }

  async createSeries(
    dto: CreatePublicEventDto,
    baseData: Prisma.CleanupEventUncheckedCreateInput,
    user: AuthenticatedUser,
    dates: Date[],
    durationMs: number,
    parentEnd: Date | null,
  ): Promise<EventMobileResponseDto> {
    const mobileEvent = await this.eventsRepository.prisma.$transaction(async (tx) => {
      const parent = await tx.cleanupEvent.create({
        data: {
          ...baseData,
          scheduledAt: dates[0],
          endAt: durationMs > 0 ? new Date(dates[0].getTime() + durationMs) : parentEnd,
          recurrenceRule: dto.recurrenceRule ?? null,
          recurrenceIndex: 0,
        },
      });

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
        include: eventDetailIncludeForViewer(user.userId),
      });

      return await this.mobileMapper.toMobileEvent(row);
    });

    const parentId = mobileEvent.id;
    let seriesMobile: EventMobileResponseDto = mobileEvent;
    if (dto.routeWaypoints != null && dto.routeWaypoints.length > 0 && parentId.length > 0) {
      await this.routeSegments.replaceWaypoints(parentId, user, dto.routeWaypoints);
      const rowWithRoute = await this.eventsRepository.prisma.cleanupEvent.findFirstOrThrow({
        where: { id: parentId },
        include: eventDetailIncludeForViewer(user.userId),
      });
      seriesMobile = await this.mobileMapper.toMobileEvent(rowWithRoute);
    }
    if (parentId.length > 0) {
      this.emitPostCreate(parentId, dto, user, baseData.status as CleanupEventStatus);
    }

    return seriesMobile;
  }
}
