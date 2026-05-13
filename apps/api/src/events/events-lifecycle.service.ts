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
  NotificationType,
  Prisma,
} from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  POINTS_EVENT_COMPLETED,
  POINTS_EVENT_JOINED,
  REASON_EVENT_COMPLETED,
  REASON_EVENT_JOIN_NO_SHOW,
  REASON_EVENT_JOINED,
} from '../gamification/gamification.constants';
import { EcoEventPointsService } from '../gamification/eco-event-points.service';
import { NotificationDispatcherService } from '../notifications/notification-dispatcher.service';
import { PatchEventLifecycleDto } from './dto/patch-event-lifecycle.dto';
import { lifecycleFromMobile } from './events-mobile.mapper';
import { canTransitionLifecycle } from './events-lifecycle.util';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import {
  eventCompletedAwardPush,
  eventCompletedNoShowPush,
} from '../common/i18n/event-user-notification.copy';
import { notificationLocalesByUserId } from '../common/i18n/notification-locale.resolver';
import { eventDetailIncludeForViewer } from './events-query.include.detail';
import { EventsRepository } from './events.repository';

/**
 * Organizer-only lifecycle transitions for cleanup events (start, complete, cancel).
 */
@Injectable()
export class EventsLifecycleService {
  private readonly logger = new Logger(EventsLifecycleService.name);

  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly mobileMapper: EventsMobileMapperService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly notificationDispatcher: NotificationDispatcherService,
  ) {}

  async patchLifecycle(id: string, dto: PatchEventLifecycleDto, user: AuthenticatedUser) {
    const existing = await this.eventsRepository.prisma.cleanupEvent.findUnique({
      where: { id },
      include: eventDetailIncludeForViewer(user.userId),
    });
    if (existing == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (existing.organizerId !== user.userId) {
      throw new ForbiddenException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can change event status',
      });
    }
    if (existing.status !== CleanupEventStatus.APPROVED) {
      throw new BadRequestException({
        code: 'EVENT_NOT_APPROVED',
        message:
          'This event is still pending approval. Once moderators approve it, you can start it from this screen.',
      });
    }

    const next = lifecycleFromMobile(dto.status);
    if (next == null) {
      throw new BadRequestException({
        code: 'INVALID_LIFECYCLE_STATUS',
        message: 'Invalid status',
      });
    }

    if (!canTransitionLifecycle(existing.lifecycleStatus, next)) {
      throw new BadRequestException({
        code: 'INVALID_LIFECYCLE_TRANSITION',
        message: 'This status transition is not allowed',
      });
    }

    if (
      next === EcoEventLifecycleStatus.IN_PROGRESS &&
      existing.lifecycleStatus === EcoEventLifecycleStatus.UPCOMING
    ) {
      const now = new Date();
      if (now < existing.scheduledAt) {
        throw new BadRequestException({
          code: 'EVENT_START_TOO_EARLY',
          message: 'The event can only be started at or after its scheduled start time.',
        });
      }
    }

    const data: Prisma.CleanupEventUpdateInput = {
      lifecycleStatus: next,
    };
    if (next === EcoEventLifecycleStatus.COMPLETED) {
      data.completedAt = new Date();
    }

    if (next !== EcoEventLifecycleStatus.COMPLETED) {
      const updated = await this.eventsRepository.prisma.cleanupEvent.update({
        where: { id },
        data,
        include: eventDetailIncludeForViewer(user.userId),
      });
      return this.mobileMapper.toMobileEvent(updated);
    }

    const { updated, completionAwards, noShowClawbacks } = await this.eventsRepository.prisma.$transaction(
      async (tx) => {
        const row = await tx.cleanupEvent.update({
          where: { id },
          data,
          include: eventDetailIncludeForViewer(user.userId),
        });
        const checkIns = await tx.eventCheckIn.findMany({
          where: { eventId: id, userId: { not: null } },
          select: { userId: true },
        });
        const checkedInUserIds = new Set(checkIns.map((c) => c.userId!));

        const joinGrantRows = await tx.pointTransaction.findMany({
          where: {
            reasonCode: REASON_EVENT_JOINED,
            referenceType: 'CleanupEvent',
            referenceId: id,
            delta: { gt: 0 },
          },
          select: { userId: true },
        });
        const joinUserIds = [...new Set(joinGrantRows.map((r) => r.userId))];
        const noShowClawbackList: { userId: string; points: number }[] = [];
        for (const uid of joinUserIds) {
          if (checkedInUserIds.has(uid)) {
            continue;
          }
          const debited = await this.ecoEventPoints.debitOnceIfNew(tx, {
            userId: uid,
            delta: -POINTS_EVENT_JOINED,
            reasonCode: REASON_EVENT_JOIN_NO_SHOW,
            referenceType: 'CleanupEvent',
            referenceId: `noShow:${id}:${uid}`,
            onlyIfPositiveGrant: {
              reasonCode: REASON_EVENT_JOINED,
              referenceType: 'CleanupEvent',
              referenceId: id,
            },
          });
          if (debited < 0) {
            noShowClawbackList.push({ userId: uid, points: debited });
          }
        }

        const userIds = [...checkedInUserIds];
        const awards: { userId: string; points: number }[] = [];
        for (const uid of userIds) {
          const points = await this.ecoEventPoints.creditIfNew(tx, {
            userId: uid,
            delta: POINTS_EVENT_COMPLETED,
            reasonCode: REASON_EVENT_COMPLETED,
            referenceType: 'CleanupEvent',
            referenceId: `completion:${id}:${uid}`,
          });
          awards.push({ userId: uid, points });
        }
        return {
          updated: row,
          completionAwards: awards,
          noShowClawbacks: noShowClawbackList,
        };
      },
    );

    const noShowRecipients = noShowClawbacks.map((n) => n.userId);
    const awardRecipients = completionAwards.filter((a) => a.points > 0).map((a) => a.userId);
    const localeByUser = await notificationLocalesByUserId(this.eventsRepository.prisma, [
      ...noShowRecipients,
      ...awardRecipients,
    ]);

    for (const { userId: recipientId, points } of noShowClawbacks) {
      const locale = localeByUser.get(recipientId) ?? 'mk';
      const { title, body } = eventCompletedNoShowPush(locale, updated.title);
      void this.notificationDispatcher
        .dispatchToUser(recipientId, {
          title,
          body,
          type: NotificationType.CLEANUP_EVENT,
          data: { eventId: id, pointsAdjusted: points },
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `No-show clawback notification failed for ${recipientId}: ${
              err instanceof Error ? err.message : String(err)
            }`,
          );
        });
    }

    for (const { userId: recipientId, points } of completionAwards) {
      if (points <= 0) {
        continue;
      }
      const locale = localeByUser.get(recipientId) ?? 'mk';
      const { title, body } = eventCompletedAwardPush(locale, updated.title, points);
      void this.notificationDispatcher
        .dispatchToUser(recipientId, {
          title,
          body,
          type: NotificationType.CLEANUP_EVENT,
          data: { eventId: id, pointsAwarded: points },
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `Completion points notification failed for ${recipientId}: ${
              err instanceof Error ? err.message : String(err)
            }`,
          );
        });
    }

    return this.mobileMapper.toMobileEvent(updated);
  }
}
