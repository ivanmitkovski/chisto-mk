import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  Prisma,
} from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  POINTS_EVENT_JOINED,
  REASON_EVENT_JOIN_LEFT,
  REASON_EVENT_JOINED,
} from '../gamification/gamification.constants';
import { EventChatMutationsService } from '../event-chat/event-chat-mutations.service';
import { EcoEventPointsService } from '../gamification/eco-event-points.service';
import { PatchEventReminderDto } from './dto/patch-event-reminder.dto';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { EventLiveImpactService } from './event-live-impact.service';
import { eventDetailIncludeForViewer } from './events-query.include.detail';
import { visibilityWhere } from './events-query.include.shared';
import { EventsRepository } from './events.repository';

/**
 * Volunteer join/leave, reminders, and related side effects (chat, live impact).
 */
@Injectable()
export class EventsParticipationService {
  private readonly logger = new Logger(EventsParticipationService.name);

  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly mobileMapper: EventsMobileMapperService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly eventChatMutations: EventChatMutationsService,
    private readonly liveImpact: EventLiveImpactService,
  ) {}

  async join(id: string, user: AuthenticatedUser) {
    const existing = await this.eventsRepository.prisma.cleanupEvent.findFirst({
      where: { id, ...visibilityWhere(user.userId) },
      include: eventDetailIncludeForViewer(user.userId),
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

        // RAW SQL: conditional increment with cap guard in a single atomic UPDATE; avoids race vs plain Prisma increment.
        const rowsAffected = await tx.$executeRaw(
          Prisma.sql`
            UPDATE "CleanupEvent"
            SET "participantCount" = "participantCount" + 1
            WHERE "id" = ${id}
              AND ("maxParticipants" IS NULL OR "participantCount" < "maxParticipants")
          `,
        );
        const updated =
          typeof rowsAffected === 'bigint' ? Number(rowsAffected) : Number(rowsAffected);
        if (updated < 1) {
          await tx.eventParticipant.delete({
            where: { eventId_userId: { eventId: id, userId: user.userId } },
          });
          throw new ConflictException({
            code: 'EVENT_FULL',
            message: 'This event has reached its participant limit',
          });
        }

        return this.ecoEventPoints.creditIfNew(tx, {
          userId: user.userId,
          delta: POINTS_EVENT_JOINED,
          reasonCode: REASON_EVENT_JOINED,
          referenceType: 'CleanupEvent',
          referenceId: id,
        });
      });
    } catch (err: unknown) {
      if (err instanceof ConflictException) {
        throw err;
      }
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
      include: eventDetailIncludeForViewer(user.userId),
    });

    const joiner = await this.eventsRepository.prisma.user.findUnique({
      where: { id: user.userId },
      select: { firstName: true, lastName: true },
    });
    const joinerName =
      joiner != null ? `${joiner.firstName} ${joiner.lastName}`.trim() : 'Someone';
    void this.eventChatMutations
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
      await this.ecoEventPoints.debitOnceIfNew(tx, {
        userId: user.userId,
        delta: -POINTS_EVENT_JOINED,
        reasonCode: REASON_EVENT_JOIN_LEFT,
        referenceType: 'CleanupEvent',
        referenceId: `leave:${id}:${user.userId}`,
        onlyIfPositiveGrant: {
          reasonCode: REASON_EVENT_JOINED,
          referenceType: 'CleanupEvent',
          referenceId: id,
        },
      });
    });

    void this.eventChatMutations
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
      include: eventDetailIncludeForViewer(user.userId),
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
      include: eventDetailIncludeForViewer(user.userId),
    });
    return this.mobileMapper.toMobileEvent(row);
  }
}
