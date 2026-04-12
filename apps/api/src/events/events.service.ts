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
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';
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
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { CreatePublicEventDto } from './dto/create-public-event.dto';
import { ListEventParticipantsQueryDto } from './dto/list-event-participants-query.dto';
import { ListEventsQueryDto } from './dto/list-events-query.dto';
import { PatchEventLifecycleDto } from './dto/patch-event-lifecycle.dto';
import { PatchEventReminderDto } from './dto/patch-event-reminder.dto';
import { PatchPublicEventDto } from './dto/patch-public-event.dto';
import {
  categoryFromMobile,
  parseCategoryFilterList,
  difficultyFromMobile,
  lifecycleFromMobile,
  normalizeGearKeys,
  parseLifecycleFilterList,
  scaleFromMobile,
} from './events-mobile.mapper';
import { RRule } from 'rrule';
import {
  decodeCursor,
  decodeParticipantCursor,
  encodeCursor,
  encodeParticipantCursor,
} from './events-cursors.util';
import { canTransitionLifecycle } from './events-lifecycle.util';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import {
  eventIncludeForViewer,
  participantDisplayName,
  visibilityWhere,
} from './events-query.include';

@Injectable()
export class EventsService {
  private readonly logger = new Logger(EventsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly uploads: ReportsUploadService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly notificationDispatcher: NotificationDispatcherService,
    private readonly eventChat: EventChatService,
    private readonly mobileMapper: EventsMobileMapperService,
  ) {}

  private isStaff(user: AuthenticatedUser): boolean {
    return ADMIN_PANEL_ROLES.includes(user.role);
  }

  async list(user: AuthenticatedUser, query: ListEventsQueryDto) {
    const limit = query.getLimit();
    const lifecycleFilter = parseLifecycleFilterList(query.status);
    if (query.status != null && query.status.trim() !== '' && lifecycleFilter == null) {
      throw new BadRequestException({
        code: 'INVALID_EVENT_STATUS_FILTER',
        message: 'Invalid status filter',
      });
    }

    const categoryList = parseCategoryFilterList(query.category);
    if (query.category != null && query.category.trim() !== '' && categoryList == null) {
      throw new BadRequestException({
        code: 'INVALID_EVENT_CATEGORY',
        message: 'Invalid category',
      });
    }

    // Full-text search: title OR description, case-insensitive.
    const searchTerm = query.q?.trim();
    const searchFilter: Prisma.CleanupEventWhereInput | null =
      searchTerm && searchTerm.length >= 2
        ? {
            OR: [
              { title: { contains: searchTerm, mode: 'insensitive' } },
              { description: { contains: searchTerm, mode: 'insensitive' } },
            ],
          }
        : null;

    // Date-range filters: inclusive, compared against scheduledAt (UTC midnight).
    const dateFromFilter: Prisma.CleanupEventWhereInput | null = query.dateFrom
      ? { scheduledAt: { gte: new Date(query.dateFrom) } }
      : null;
    const dateToFilter: Prisma.CleanupEventWhereInput | null = query.dateTo
      ? {
          scheduledAt: {
            // Include entire day by advancing to the start of the next day.
            lt: new Date(
              new Date(query.dateTo).setDate(new Date(query.dateTo).getDate() + 1),
            ),
          },
        }
      : null;

    const baseWhere: Prisma.CleanupEventWhereInput = {
      AND: [
        visibilityWhere(user.userId),
        ...(query.siteId?.trim()
          ? [{ siteId: query.siteId.trim() } satisfies Prisma.CleanupEventWhereInput]
          : []),
        ...(lifecycleFilter != null && lifecycleFilter.length > 0
          ? [{ lifecycleStatus: { in: lifecycleFilter } }]
          : []),
        ...(categoryList != null && categoryList.length > 0
          ? [{ category: { in: categoryList } } satisfies Prisma.CleanupEventWhereInput]
          : []),
        ...(searchFilter != null ? [searchFilter] : []),
        ...(dateFromFilter != null ? [dateFromFilter] : []),
        ...(dateToFilter != null ? [dateToFilter] : []),
      ],
    };

    let cursorClause: Prisma.CleanupEventWhereInput = {};
    if (query.cursor != null && query.cursor.trim() !== '') {
      const { scheduledAt, id } = decodeCursor(query.cursor.trim());
      cursorClause = {
        OR: [
          { scheduledAt: { lt: scheduledAt } },
          { AND: [{ scheduledAt }, { id: { lt: id } }] },
        ],
      };
    }

    const where: Prisma.CleanupEventWhereInput = {
      AND: [baseWhere, cursorClause],
    };

    const rows = await this.prisma.cleanupEvent.findMany({
      where,
      orderBy: [{ scheduledAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      include: eventIncludeForViewer(user.userId),
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const last = page[page.length - 1];
    const nextCursor =
      hasMore && last != null ? encodeCursor(last.scheduledAt, last.id) : null;

    const data = await Promise.all(page.map((row) => this.mobileMapper.toMobileEvent(row)));

    return {
      data,
      meta: {
        hasMore,
        nextCursor,
      },
    };
  }

  async findOne(id: string, user: AuthenticatedUser) {
    const row = await this.prisma.cleanupEvent.findFirst({
      where: {
        id,
        ...visibilityWhere(user.userId),
      },
      include: eventIncludeForViewer(user.userId),
    });
    if (row == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    return this.mobileMapper.toMobileEvent(row);
  }

  /**
   * Paginated joiners for an event (organizer is not an EventParticipant row).
   * Ordered by joinedAt ascending, then id ascending.
   */
  async listParticipants(
    id: string,
    user: AuthenticatedUser,
    query: ListEventParticipantsQueryDto,
  ) {
    const visible = await this.prisma.cleanupEvent.findFirst({
      where: {
        id,
        ...visibilityWhere(user.userId),
      },
      select: { id: true },
    });
    if (visible == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    const limit = query.getLimit();
    let cursorClause: Prisma.EventParticipantWhereInput = {};
    if (query.cursor != null && query.cursor.trim() !== '') {
      const { joinedAt, participantId } = decodeParticipantCursor(query.cursor.trim());
      cursorClause = {
        OR: [
          { joinedAt: { gt: joinedAt } },
          { AND: [{ joinedAt }, { id: { gt: participantId } }] },
        ],
      };
    }

    const rows = await this.prisma.eventParticipant.findMany({
      where: {
        eventId: id,
        ...cursorClause,
      },
      orderBy: [{ joinedAt: 'asc' }, { id: 'asc' }],
      take: limit + 1,
      select: {
        id: true,
        joinedAt: true,
        userId: true,
        user: {
          select: { firstName: true, lastName: true, avatarObjectKey: true },
        },
      },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const last = page[page.length - 1];
    const nextCursor =
      hasMore && last != null ? encodeParticipantCursor(last.joinedAt, last.id) : null;

    const data = await Promise.all(
      page.map(async (row) => ({
        userId: row.userId,
        displayName: participantDisplayName(row.user),
        avatarUrl: await this.uploads.signPrivateObjectKey(row.user.avatarObjectKey),
        joinedAt: row.joinedAt.toISOString(),
      })),
    );

    return {
      data,
      meta: {
        hasMore,
        nextCursor,
      },
    };
  }

  async create(dto: CreatePublicEventDto, user: AuthenticatedUser) {
    const category = categoryFromMobile(dto.category);
    if (category == null) {
      throw new BadRequestException({
        code: 'INVALID_EVENT_CATEGORY',
        message: 'Invalid category',
      });
    }
    const scheduledAt = new Date(dto.scheduledAt);
    if (Number.isNaN(scheduledAt.getTime())) {
      throw new BadRequestException({
        code: 'INVALID_SCHEDULED_AT',
        message: 'Invalid scheduledAt',
      });
    }
    let endAt: Date | null = null;
    if (dto.endAt != null && dto.endAt.trim() !== '') {
      endAt = new Date(dto.endAt);
      if (Number.isNaN(endAt.getTime()) || endAt.getTime() <= scheduledAt.getTime()) {
        throw new BadRequestException({
          code: 'INVALID_END_AT',
          message: 'endAt must be after scheduledAt',
        });
      }
    }

    const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
    if (site == null) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: 'Site not found',
      });
    }

    const scale = scaleFromMobile(dto.scale);
    const difficulty = difficultyFromMobile(dto.difficulty);
    const gear = normalizeGearKeys(dto.gear);
    const moderation = this.isStaff(user) ? CleanupEventStatus.APPROVED : CleanupEventStatus.PENDING;

    const createData: Prisma.CleanupEventUncheckedCreateInput = {
      siteId: dto.siteId,
      title: dto.title.trim(),
      description: dto.description.trim(),
      category,
      scheduledAt,
      endAt,
      organizerId: user.userId,
      status: moderation,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      participantCount: 0,
      maxParticipants: dto.maxParticipants ?? null,
      gear,
    };
    if (scale != null) {
      createData.scale = scale;
    }
    if (difficulty != null) {
      createData.difficulty = difficulty;
    }

    // If a recurrence rule is provided, build the full series before returning the parent.
    if (dto.recurrenceRule != null && dto.recurrenceRule.trim() !== '') {
      return this.createSeries(dto, createData, user, scheduledAt, endAt);
    }

    const created = await this.prisma.cleanupEvent.create({
      data: createData,
    });

    const row = await this.prisma.cleanupEvent.findFirstOrThrow({
      where: { id: created.id },
      include: eventIncludeForViewer(user.userId),
    });

    return this.mobileMapper.toMobileEvent(row);
  }

  /**
   * Creates a recurring series of [CleanupEvent] rows inside a Prisma transaction.
   * The first event is the "parent" (recurrenceIndex = 0); subsequent events reference it
   * via parentEventId. Capped at 52 occurrences regardless of the RRULE COUNT/UNTIL.
   */
  private async createSeries(
    dto: CreatePublicEventDto,
    baseData: Prisma.CleanupEventUncheckedCreateInput,
    user: AuthenticatedUser,
    parentStart: Date,
    parentEnd: Date | null,
  ) {
    const count = Math.min(dto.recurrenceCount ?? 4, 52);
    let dates: Date[];
    try {
      const rule = RRule.fromString(
        dto.recurrenceRule!.startsWith('RRULE:')
          ? dto.recurrenceRule!
          : `RRULE:${dto.recurrenceRule}`,
      );
      // Start from the parent scheduled date and compute `count` occurrences.
      dates = rule.all((_, len) => len < count);
      // Fallback to parent-only if rrule produces no dates.
      if (dates.length === 0) {
        dates = [parentStart];
      }
    } catch {
      throw new BadRequestException({
        code: 'INVALID_RECURRENCE_RULE',
        message: 'Could not parse recurrenceRule as a valid RFC 5545 RRULE',
      });
    }

    const durationMs = parentEnd != null ? parentEnd.getTime() - parentStart.getTime() : 0;

    return this.prisma.$transaction(async (tx) => {
      // Create the parent event (index 0).
      const parent = await tx.cleanupEvent.create({
        data: {
          ...baseData,
          scheduledAt: dates[0],
          endAt: durationMs > 0 ? new Date(dates[0].getTime() + durationMs) : parentEnd,
          recurrenceRule: dto.recurrenceRule ?? null,
          recurrenceIndex: 0,
        },
      });

      // Create the child events in bulk.
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
        include: eventIncludeForViewer(user.userId),
      });

      return this.mobileMapper.toMobileEvent(row);
    });
  }

  async patchEvent(id: string, dto: PatchPublicEventDto, user: AuthenticatedUser) {
    const existing = await this.prisma.cleanupEvent.findUnique({
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
        message: 'Only the organizer can update this event',
      });
    }

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
        data.endAt = end;
      }
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

    const updated = await this.prisma.cleanupEvent.update({
      where: { id },
      data,
      include: eventIncludeForViewer(user.userId),
    });

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
      void this.eventChat
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

    return this.mobileMapper.toMobileEvent(updated);
  }

  async patchLifecycle(id: string, dto: PatchEventLifecycleDto, user: AuthenticatedUser) {
    const existing = await this.prisma.cleanupEvent.findUnique({
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
      const updated = await this.prisma.cleanupEvent.update({
        where: { id },
        data,
        include: eventIncludeForViewer(user.userId),
      });
      return this.mobileMapper.toMobileEvent(updated);
    }

    const { updated, completionAwards, noShowClawbacks } = await this.prisma.$transaction(
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
    const existing = await this.prisma.cleanupEvent.findFirst({
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
      pointsAwarded = await this.prisma.$transaction(async (tx) => {
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

    const row = await this.prisma.cleanupEvent.findFirstOrThrow({
      where: { id },
      include: eventIncludeForViewer(user.userId),
    });

    const joiner = await this.prisma.user.findUnique({
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

    return { ...(await this.mobileMapper.toMobileEvent(row)), pointsAwarded };
  }

  async leave(id: string, user: AuthenticatedUser) {
    const existing = await this.prisma.cleanupEvent.findFirst({
      where: { id, ...visibilityWhere(user.userId) },
    });
    if (existing == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    const leaver = await this.prisma.user.findUnique({
      where: { id: user.userId },
      select: { firstName: true, lastName: true },
    });
    const leaverName =
      leaver != null ? `${leaver.firstName} ${leaver.lastName}`.trim() : 'Someone';

    await this.prisma.$transaction(async (tx) => {
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

    const row = await this.prisma.cleanupEvent.findFirstOrThrow({
      where: { id },
      include: eventIncludeForViewer(user.userId),
    });
    return this.mobileMapper.toMobileEvent(row);
  }

  async patchReminder(id: string, dto: PatchEventReminderDto, user: AuthenticatedUser) {
    const existing = await this.prisma.cleanupEvent.findFirst({
      where: { id, ...visibilityWhere(user.userId) },
    });
    if (existing == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    const participant = await this.prisma.eventParticipant.findUnique({
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

    await this.prisma.eventParticipant.update({
      where: { eventId_userId: { eventId: id, userId: user.userId } },
      data: {
        reminderEnabled: dto.reminderEnabled,
        reminderAt: dto.reminderEnabled ? reminderAt : null,
      },
    });

    const row = await this.prisma.cleanupEvent.findFirstOrThrow({
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
    const existing = await this.prisma.cleanupEvent.findUnique({
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

    const updated = await this.prisma.cleanupEvent.update({
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
    const event = await this.prisma.cleanupEvent.findUnique({
      where: { id },
      select: { organizerId: true, participantCount: true, checkedInCount: true },
    });
    if (event == null) {
      throw new NotFoundException({ code: 'EVENT_NOT_FOUND', message: 'Event not found' });
    }
    if (event.organizerId !== user.userId && !this.isStaff(user)) {
      throw new UnauthorizedException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can view analytics',
      });
    }

    // Joiners over time: group EventParticipant rows by joinedAt date.
    const participants = await this.prisma.eventParticipant.findMany({
      where: { eventId: id },
      select: { joinedAt: true },
      orderBy: { joinedAt: 'asc' },
    });

    const joinersMap = new Map<string, number>();
    for (const p of participants) {
      const dateKey = p.joinedAt.toISOString().slice(0, 10);
      joinersMap.set(dateKey, (joinersMap.get(dateKey) ?? 0) + 1);
    }
    const joinersOverTime = Array.from(joinersMap.entries()).map(([date, count]) => ({
      date,
      count,
    }));

    // Check-ins by hour.
    const checkIns = await this.prisma.eventCheckIn.findMany({
      where: { eventId: id },
      select: { checkedInAt: true },
    });

    const hourMap = new Map<number, number>();
    for (const c of checkIns) {
      const hour = c.checkedInAt.getHours();
      hourMap.set(hour, (hourMap.get(hour) ?? 0) + 1);
    }
    const checkInsByHour = Array.from(hourMap.entries())
      .sort(([a], [b]) => a - b)
      .map(([hour, count]) => ({ hour, count }));

    const totalJoiners = event.participantCount;
    const checkedInCount = event.checkedInCount;
    const attendanceRate =
      totalJoiners > 0 ? Math.round((checkedInCount / totalJoiners) * 100) : 0;

    return {
      totalJoiners,
      checkedInCount,
      attendanceRate,
      joinersOverTime,
      checkInsByHour,
    };
  }
}
