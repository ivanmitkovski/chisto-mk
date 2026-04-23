import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
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
import { EventChatService } from '../event-chat/event-chat.service';
import { EcoEventPointsService } from '../gamification/eco-event-points.service';
import { NotificationDispatcherService } from '../notifications/notification-dispatcher.service';
import { buildEventAnalyticsPayload } from './event-analytics.aggregation';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { PatchEventLifecycleDto } from './dto/patch-event-lifecycle.dto';
import { PatchEventReminderDto } from './dto/patch-event-reminder.dto';
import { lifecycleFromMobile } from './events-mobile.mapper';
import { canTransitionLifecycle } from './events-lifecycle.util';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventLiveImpactService } from './event-live-impact.service';
import {
  eventIncludeForViewer,
  visibilityWhere,
} from './events-query.include';
import { EventsRepository } from './events.repository';
import { isEventsStaff } from './events-auth.util';


@Injectable()
export class EventsLifecycleParticipationService {
  private readonly logger = new Logger(EventsLifecycleParticipationService.name);

  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly uploads: ReportsUploadService,
    private readonly mobileMapper: EventsMobileMapperService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly notificationDispatcher: NotificationDispatcherService,
    private readonly eventChat: EventChatService,
    private readonly liveImpact: EventLiveImpactService,
  ) {}

  async patchLifecycle(id: string, dto: PatchEventLifecycleDto, user: AuthenticatedUser) {
    const existing = await this.eventsRepository.prisma.cleanupEvent.findUnique({
      where: { id },
      include: eventIncludeForViewer(user.userId),
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
        include: eventIncludeForViewer(user.userId),
      });
      return this.mobileMapper.toMobileEvent(updated);
    }

    const { updated, completionAwards, noShowClawbacks } = await this.eventsRepository.prisma.$transaction(
      async (tx) => {
        const row = await tx.cleanupEvent.update({
          where: { id },
          data,
          include: eventIncludeForViewer(user.userId),
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

    for (const { userId: recipientId, points } of noShowClawbacks) {
      void this.notificationDispatcher
        .dispatchToUser(recipientId, {
          title: 'Event completed',
          body: `Your join bonus for "${updated.title}" was removed because no check-in was recorded.`,
          type: NotificationType.CLEANUP_EVENT,
          data: { eventId: id, pointsAdjusted: points },
        })
        .catch((err: unknown) => {
          this.logger.warn(`No-show clawback notification failed for ${recipientId}`, err);
        });
    }

    for (const { userId: recipientId, points } of completionAwards) {
      if (points <= 0) {
        continue;
      }
      void this.notificationDispatcher
        .dispatchToUser(recipientId, {
          title: 'Event completed',
          body: `You earned ${points} points for taking part in "${updated.title}".`,
          type: NotificationType.CLEANUP_EVENT,
          data: { eventId: id, pointsAwarded: points },
        })
        .catch((err: unknown) => {
          this.logger.warn(`Completion points notification failed for ${recipientId}`, err);
        });
    }

    return this.mobileMapper.toMobileEvent(updated);
  }

  async join(id: string, user: AuthenticatedUser) {
    const existing = await this.eventsRepository.prisma.cleanupEvent.findFirst({
      where: { id, ...visibilityWhere(user.userId) },
      include: eventIncludeForViewer(user.userId),
    });
    if (existing == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (existing.status !== CleanupEventStatus.APPROVED) {
      throw new BadRequestException({
        code: 'EVENT_NOT_JOINABLE',
        message: 'This event is not open for participation',
      });
    }
    if (
      existing.lifecycleStatus === EcoEventLifecycleStatus.COMPLETED ||
      existing.lifecycleStatus === EcoEventLifecycleStatus.CANCELLED
    ) {
      throw new BadRequestException({
        code: 'EVENT_NOT_JOINABLE',
        message: 'This event is not open for participation',
      });
    }
    if (existing.organizerId === user.userId) {
      throw new BadRequestException({
        code: 'ORGANIZER_CANNOT_JOIN',
        message: 'Organizers join implicitly; use the organizer tools instead',
      });
    }
    const volunteerJoinGraceMs = 15 * 60 * 1000;
    const joinDeadlineMs = existing.scheduledAt.getTime() + volunteerJoinGraceMs;
    if (Date.now() >= joinDeadlineMs) {
      throw new BadRequestException({
        code: 'EVENT_JOIN_WINDOW_CLOSED',
        message:
          'Joining is closed for this event. Volunteers could join until 15 minutes after the scheduled start.',
      });
    }
    if (
      existing.maxParticipants != null &&
      existing.participantCount >= existing.maxParticipants
    ) {
      throw new ConflictException({
        code: 'EVENT_FULL',
        message: 'This event has reached its participant limit',
      });
    }

    let pointsAwarded = 0;
    try {
      pointsAwarded = await this.eventsRepository.prisma.$transaction(async (tx) => {
        await tx.eventParticipant.create({
          data: {
            eventId: id,
            userId: user.userId,
          },
        });
        await tx.cleanupEvent.update({
          where: { id },
          data: { participantCount: { increment: 1 } },
        });
        return this.ecoEventPoints.creditIfNew(tx, {
          userId: user.userId,
          delta: POINTS_EVENT_JOINED,
          reasonCode: REASON_EVENT_JOINED,
          referenceType: 'CleanupEvent',
          referenceId: id,
        });
      });
    } catch (err: unknown) {
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        throw new ConflictException({
          code: 'ALREADY_JOINED',
          message: 'You are already registered for this event',
        });
      }
      throw err;
    }

    const row = await this.eventsRepository.prisma.cleanupEvent.findFirstOrThrow({
      where: { id },
      include: eventIncludeForViewer(user.userId),
    });

    const joiner = await this.eventsRepository.prisma.user.findUnique({
      where: { id: user.userId },
      select: { firstName: true, lastName: true },
    });
    const joinerName =
      joiner != null ? `${joiner.firstName} ${joiner.lastName}`.trim() : 'Someone';
    void this.eventChat
      .createSystemMessage({
        eventId: id,
        authorId: user.userId,
        body: `${joinerName} joined the event`,
        systemPayload: {
          action: 'user_joined',
          userId: user.userId,
          displayName: joinerName,
        },
      })
      .catch((err: unknown) => {
        this.logger.warn(`Event chat system message (join) failed: ${String(err)}`);
      });

    this.liveImpact.notifyListeners(id);
    return { ...(await this.mobileMapper.toMobileEvent(row)), pointsAwarded };
  }

  async leave(id: string, user: AuthenticatedUser) {
    const existing = await this.eventsRepository.prisma.cleanupEvent.findFirst({
      where: { id, ...visibilityWhere(user.userId) },
    });
    if (existing == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    const leaver = await this.eventsRepository.prisma.user.findUnique({
      where: { id: user.userId },
      select: { firstName: true, lastName: true },
    });
    const leaverName =
      leaver != null ? `${leaver.firstName} ${leaver.lastName}`.trim() : 'Someone';

    await this.eventsRepository.prisma.$transaction(async (tx) => {
      const deleted = await tx.eventParticipant.deleteMany({
        where: { eventId: id, userId: user.userId },
      });
      if (deleted.count === 0) {
        throw new BadRequestException({
          code: 'NOT_A_PARTICIPANT',
          message: 'You are not registered for this event',
        });
      }
      await tx.cleanupEvent.update({
        where: { id },
        data: {
          participantCount: { decrement: 1 },
        },
      });
    });

    void this.eventChat
      .createSystemMessage({
        eventId: id,
        authorId: user.userId,
        body: `${leaverName} left the event`,
        systemPayload: {
          action: 'user_left',
          userId: user.userId,
          displayName: leaverName,
        },
      })
      .catch((err: unknown) => {
        this.logger.warn(`Event chat system message (leave) failed: ${String(err)}`);
      });

    const row = await this.eventsRepository.prisma.cleanupEvent.findFirstOrThrow({
      where: { id },
      include: eventIncludeForViewer(user.userId),
    });
    this.liveImpact.notifyListeners(id);
    return this.mobileMapper.toMobileEvent(row);
  }

  async patchReminder(id: string, dto: PatchEventReminderDto, user: AuthenticatedUser) {
    const existing = await this.eventsRepository.prisma.cleanupEvent.findFirst({
      where: { id, ...visibilityWhere(user.userId) },
    });
    if (existing == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    const participant = await this.eventsRepository.prisma.eventParticipant.findUnique({
      where: {
        eventId_userId: { eventId: id, userId: user.userId },
      },
    });
    if (participant == null) {
      throw new ForbiddenException({
        code: 'REMINDER_REQUIRES_JOIN',
        message: 'Join the event before setting a reminder',
      });
    }

    let reminderAt: Date | null = null;
    if (dto.reminderEnabled && dto.reminderAt != null && dto.reminderAt !== '') {
      reminderAt = new Date(dto.reminderAt);
      if (Number.isNaN(reminderAt.getTime())) {
        throw new BadRequestException({
          code: 'INVALID_REMINDER_AT',
          message: 'Invalid reminderAt',
        });
      }
    }

    await this.eventsRepository.prisma.eventParticipant.update({
      where: { eventId_userId: { eventId: id, userId: user.userId } },
      data: {
        reminderEnabled: dto.reminderEnabled,
        reminderAt: dto.reminderEnabled ? reminderAt : null,
      },
    });

    const row = await this.eventsRepository.prisma.cleanupEvent.findFirstOrThrow({
      where: { id },
      include: eventIncludeForViewer(user.userId),
    });
    return this.mobileMapper.toMobileEvent(row);
  }

  async appendAfterImages(
    id: string,
    files: Express.Multer.File[],
    user: AuthenticatedUser,
  ) {
    const existing = await this.eventsRepository.prisma.cleanupEvent.findUnique({
      where: { id },
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
        message: 'Only the organizer can upload after photos',
      });
    }
    if (existing.status !== CleanupEventStatus.APPROVED) {
      throw new BadRequestException({
        code: 'EVENT_NOT_APPROVED',
        message: 'After photos can only be added to approved events',
      });
    }

    const buffers = (files ?? []).map((f) => ({
      buffer: f.buffer,
      mimetype: f.mimetype,
      size: f.size,
      originalname: f.originalname,
    }));

    const keys = await this.uploads.uploadCleanupEventAfterImages(user.userId, id, buffers);
    const merged = [...existing.afterImageKeys, ...keys];

    const updated = await this.eventsRepository.prisma.cleanupEvent.update({
      where: { id },
      data: { afterImageKeys: merged },
      include: eventIncludeForViewer(user.userId),
    });

    return this.mobileMapper.toMobileEvent(updated);
  }

  /**
   * Returns attendance analytics for a single event.
   * Only the organizer may access this endpoint.
   */
  async getAnalytics(id: string, user: AuthenticatedUser) {
    const event = await this.eventsRepository.prisma.cleanupEvent.findUnique({
      where: { id },
      select: { organizerId: true, participantCount: true },
    });
    if (event == null) {
      throw new NotFoundException({ code: 'EVENT_NOT_FOUND', message: 'Event not found' });
    }
    if (event.organizerId !== user.userId && !isEventsStaff(user)) {
      throw new UnauthorizedException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can view analytics',
      });
    }

    const [participants, checkIns] = await Promise.all([
      this.eventsRepository.prisma.eventParticipant.findMany({
        where: { eventId: id },
        select: { joinedAt: true },
        orderBy: { joinedAt: 'asc' },
      }),
      this.eventsRepository.prisma.eventCheckIn.findMany({
        where: { eventId: id },
        select: { checkedInAt: true },
      }),
    ]);

    return buildEventAnalyticsPayload({
      participantCount: event.participantCount,
      participantsJoinedAt: participants.map((p) => p.joinedAt),
      checkInsCheckedAt: checkIns.map((c) => c.checkedInAt),
    });
  }
}
