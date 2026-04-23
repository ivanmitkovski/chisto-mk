import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { duplicateEventConflict } from '../event-schedule-conflict/duplicate-event-conflict.exception';
import { EventScheduleConflictService } from '../event-schedule-conflict/event-schedule-conflict.service';
import { CleanupEventStatus, EcoEventLifecycleStatus, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { buildEventAnalyticsPayload } from '../events/event-analytics.aggregation';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import {
  POINTS_EVENT_ORGANIZER_APPROVED,
  REASON_EVENT_ORGANIZER_APPROVED,
} from '../gamification/gamification.constants';
import { EcoEventPointsService } from '../gamification/eco-event-points.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { CleanupEventsEventsService } from '../admin-events/cleanup-events-events.service';
import { CleanupEventNotificationsService } from '../notifications/cleanup-event-notifications.service';
import { ObservabilityStore } from '../observability/observability.store';
import {
  assertEndSameSkopjeCalendarDayUtc,
  defaultEndSameSkopjeCalendarDayUtc,
} from '../common/validation/event-calendar-span.validation';
import { CreateCleanupEventDto } from './dto/create-cleanup-event.dto';
import { PatchCleanupEventDto } from './dto/patch-cleanup-event.dto';
import { ListCleanupEventsQueryDto } from './dto/list-cleanup-events-query.dto';
import { BulkModerateCleanupEventsDto } from './dto/bulk-moderate-cleanup-events.dto';
import { ListCheckInRiskSignalsQueryDto } from './dto/list-check-in-risk-signals-query.dto';

const AUDIT_TRAIL_LIMIT = 50;

@Injectable()
export class CleanupEventsService {
  private readonly logger = new Logger(CleanupEventsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly uploads: ReportsUploadService,
    private readonly cleanupEventsSse: CleanupEventsEventsService,
    private readonly scheduleConflict: EventScheduleConflictService,
    private readonly cleanupEventNotifications: CleanupEventNotificationsService,
  ) {}

  private eventInclude() {
    return {
      site: {
        select: {
          id: true,
          latitude: true,
          longitude: true,
          description: true,
          status: true,
        },
      },
      organizer: {
        select: { id: true, firstName: true, lastName: true, email: true },
      },
      _count: { select: { seriesChildren: true } },
    } as const;
  }

  private mapOrganizer(
    o: { id: string; firstName: string; lastName: string; email: string } | null,
  ) {
    if (!o) {
      return null;
    }
    const displayName = `${o.firstName} ${o.lastName}`.trim();
    return { id: o.id, displayName: displayName.length > 0 ? displayName : o.email, email: o.email };
  }

  private mapListRow(e: {
    id: string;
    createdAt: Date;
    title: string;
    description: string;
    siteId: string;
    scheduledAt: Date;
    completedAt: Date | null;
    endAt: Date | null;
    organizerId: string | null;
    participantCount: number;
    status: CleanupEventStatus;
    lifecycleStatus: EcoEventLifecycleStatus;
    recurrenceRule: string | null;
    recurrenceIndex: number | null;
    parentEventId: string | null;
    category: string;
    scale: string | null;
    difficulty: string | null;
    gear: string[];
    maxParticipants: number | null;
    checkInOpen: boolean;
    checkedInCount: number;
    site: {
      id: string;
      latitude: number;
      longitude: number;
      description: string | null;
      status: string;
    };
    organizer: { id: string; firstName: string; lastName: string; email: string } | null;
    _count: { seriesChildren: number };
  }) {
    return {
      id: e.id,
      createdAt: e.createdAt.toISOString(),
      title: e.title,
      description: e.description,
      siteId: e.siteId,
      scheduledAt: e.scheduledAt.toISOString(),
      endAt: e.endAt?.toISOString() ?? null,
      completedAt: e.completedAt?.toISOString() ?? null,
      organizerId: e.organizerId,
      participantCount: e.participantCount,
      status: e.status,
      lifecycleStatus: e.lifecycleStatus,
      recurrenceRule: e.recurrenceRule ?? null,
      recurrenceIndex: e.recurrenceIndex ?? null,
      parentEventId: e.parentEventId ?? null,
      seriesChildrenCount: e._count.seriesChildren,
      category: e.category,
      scale: e.scale,
      difficulty: e.difficulty,
      gear: e.gear,
      maxParticipants: e.maxParticipants,
      checkInOpen: e.checkInOpen,
      checkedInCount: e.checkedInCount,
      site: e.site,
      organizer: this.mapOrganizer(e.organizer),
    };
  }

  async list(query: ListCleanupEventsQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: Prisma.CleanupEventWhereInput = {};
    if (query.status === 'upcoming') {
      where.lifecycleStatus = {
        in: [EcoEventLifecycleStatus.UPCOMING, EcoEventLifecycleStatus.IN_PROGRESS],
      };
    } else if (query.status === 'completed') {
      where.lifecycleStatus = EcoEventLifecycleStatus.COMPLETED;
    }
    if (query.moderationStatus) {
      where.status = query.moderationStatus as CleanupEventStatus;
    }

    const orderBy: Prisma.CleanupEventOrderByWithRelationInput[] =
      query.moderationStatus === 'PENDING'
        ? [{ createdAt: 'asc' }, { id: 'asc' }]
        : [{ scheduledAt: 'desc' }, { id: 'desc' }];

    const [rows, total] = await this.prisma.$transaction([
      this.prisma.cleanupEvent.findMany({
        where,
        orderBy,
        skip,
        take: limit,
        include: this.eventInclude(),
      }),
      this.prisma.cleanupEvent.count({ where }),
    ]);

    return {
      data: rows.map((e) => this.mapListRow(e)),
      meta: { page, limit, total },
    };
  }

  async findOne(id: string) {
    const e = await this.prisma.cleanupEvent.findUnique({
      where: { id },
      include: this.eventInclude(),
    });
    if (!e) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOT_FOUND',
        message: 'Cleanup event not found',
      });
    }
    const afterImageUrls = await this.uploads.signUrls(this.uploads.getPublicUrlsForKeys(e.afterImageKeys));
    return {
      ...this.mapListRow(e),
      afterImageKeys: e.afterImageKeys,
      afterImageUrls,
    };
  }

  async getAnalytics(id: string) {
    const event = await this.prisma.cleanupEvent.findUnique({
      where: { id },
      select: { participantCount: true },
    });
    if (event == null) {
      throw new NotFoundException({ code: 'CLEANUP_EVENT_NOT_FOUND', message: 'Cleanup event not found' });
    }

    const [participants, checkIns] = await Promise.all([
      this.prisma.eventParticipant.findMany({
        where: { eventId: id },
        select: { joinedAt: true },
        orderBy: { joinedAt: 'asc' },
      }),
      this.prisma.eventCheckIn.findMany({
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

  async listAuditTrail(id: string, query: { page?: number; limit?: number }) {
    const existing = await this.prisma.cleanupEvent.findUnique({ where: { id }, select: { id: true } });
    if (!existing) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOT_FOUND',
        message: 'Cleanup event not found',
      });
    }
    const page = query.page ?? 1;
    const limit = Math.min(query.limit ?? AUDIT_TRAIL_LIMIT, 100);
    return this.audit.listForAdmin({
      page,
      limit,
      resourceType: 'CleanupEvent',
      resourceId: id,
    });
  }

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

    const out = await this.findOne(e.id);
    if (status === CleanupEventStatus.PENDING) {
      this.cleanupEventsSse.emitCleanupEventPending(e.id);
      void this.cleanupEventNotifications
        .notifyStaffPendingReview({
          eventId: e.id,
          siteId: dto.siteId,
          title,
        })
        .catch((err: unknown) => {
          this.logger.warn(`notify staff pending failed for ${e.id}`, err);
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
          this.logger.warn(`notify audience published failed for ${e.id}`, err);
        });
    }
    return out;
  }

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
      if (r.length === 0) {
        throw new BadRequestException({
          code: 'DECLINE_REASON_REQUIRED',
          message: 'A decline reason is required',
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
    if (dto.status === CleanupEventStatus.APPROVED || dto.status === CleanupEventStatus.DECLINED) {
      if (existing.status !== CleanupEventStatus.PENDING) {
        throw new BadRequestException({
          code: 'EVENT_NOT_PENDING',
          message: 'Only PENDING events can be approved or declined',
        });
      }
      data.status = dto.status;
    }

    /** Approve/decline-only: do not re-validate stored span (legacy rows may predate stricter rules). */
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

    const out = await this.findOne(id);
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
          this.logger.warn(`notify audience published failed for ${id}`, err);
        });
      if (existing.organizerId != null) {
        void this.cleanupEventNotifications
          .notifyOrganizerApproved({
            organizerId: existing.organizerId,
            eventId: id,
            title: out.title,
          })
          .catch((err: unknown) => {
            this.logger.warn(`notify organizer approved failed for ${id}`, err);
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
          this.logger.warn(`notify organizer declined failed for ${id}`, err);
        });
    }

    return out;
  }

  async bulkModerate(dto: BulkModerateCleanupEventsDto, actor: AuthenticatedUser) {
    if (dto.eventIds.length === 0) {
      throw new BadRequestException({
        code: 'BULK_MODERATION_EMPTY',
        message: 'eventIds must not be empty',
      });
    }

    try {
      await this.prisma.adminMutationIdempotency.create({
        data: {
          actorUserId: actor.userId,
          purpose: 'bulk_cleanup_moderate',
          clientJobId: dto.clientJobId,
        },
      });
    } catch (e: unknown) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        throw new ConflictException({
          code: 'DUPLICATE_BULK_MODERATION_JOB',
          message: 'This moderation job was already submitted.',
        });
      }
      throw e;
    }

    const failed: Array<{ id: string; code: string; message: string }> = [];
    let processed = 0;
    for (const eventId of dto.eventIds) {
      try {
        if (dto.action === 'APPROVED') {
          await this.patch(eventId, { status: CleanupEventStatus.APPROVED }, actor);
        } else {
          await this.patch(
            eventId,
            {
              status: CleanupEventStatus.DECLINED,
              declineReason: dto.declineReason ?? '',
            },
            actor,
          );
        }
        processed += 1;
      } catch (err: unknown) {
        const body = err instanceof BadRequestException || err instanceof NotFoundException ? err.getResponse() : null;
        const code =
          typeof body === 'object' && body !== null && 'code' in body && typeof (body as { code: unknown }).code === 'string'
            ? (body as { code: string }).code
            : 'UNKNOWN';
        const message =
          typeof body === 'object' && body !== null && 'message' in body && typeof (body as { message: unknown }).message === 'string'
            ? (body as { message: string }).message
            : 'Request failed';
        failed.push({ id: eventId, code, message });
      }
    }

    return { processed, failed, clientJobId: dto.clientJobId };
  }

  async listCheckInRiskSignals(query: ListCheckInRiskSignalsQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 50;
    const skip = (page - 1) * limit;
    const now = new Date();
    const where = { expiresAt: { gt: now } };
    const [rows, total] = await Promise.all([
      this.prisma.checkInRiskSignal.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        select: {
          id: true,
          createdAt: true,
          expiresAt: true,
          eventId: true,
          userId: true,
          signalType: true,
          metadata: true,
          event: { select: { title: true } },
          user: { select: { firstName: true, lastName: true } },
        },
      }),
      this.prisma.checkInRiskSignal.count({ where }),
    ]);
    return {
      data: rows.map((r) => ({
        id: r.id,
        createdAt: r.createdAt.toISOString(),
        expiresAt: r.expiresAt.toISOString(),
        eventId: r.eventId,
        eventTitle: r.event.title,
        userId: r.userId,
        userDisplayName: `${r.user.firstName} ${r.user.lastName}`.trim(),
        signalType: r.signalType,
        metadata: r.metadata,
      })),
      page,
      limit,
      total,
    };
  }
}
