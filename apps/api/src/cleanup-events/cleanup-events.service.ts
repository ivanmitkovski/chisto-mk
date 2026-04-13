import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { CleanupEventStatus, EcoEventLifecycleStatus, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import {
  POINTS_EVENT_ORGANIZER_APPROVED,
  REASON_EVENT_ORGANIZER_APPROVED,
} from '../gamification/gamification.constants';
import { EcoEventPointsService } from '../gamification/eco-event-points.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { CleanupEventsEventsService } from '../admin-events/cleanup-events-events.service';
import { CreateCleanupEventDto } from './dto/create-cleanup-event.dto';
import { PatchCleanupEventDto } from './dto/patch-cleanup-event.dto';
import { ListCleanupEventsQueryDto } from './dto/list-cleanup-events-query.dto';

const AUDIT_TRAIL_LIMIT = 50;

@Injectable()
export class CleanupEventsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly uploads: ReportsUploadService,
    private readonly cleanupEventsSse: CleanupEventsEventsService,
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

    const [rows, total] = await this.prisma.$transaction([
      this.prisma.cleanupEvent.findMany({
        where,
        orderBy: { scheduledAt: 'desc' },
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
      select: { participantCount: true, checkedInCount: true },
    });
    if (event == null) {
      throw new NotFoundException({ code: 'CLEANUP_EVENT_NOT_FOUND', message: 'Cleanup event not found' });
    }

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
    const joinersOverTime = Array.from(joinersMap.entries()).map(([date, count]) => ({ date, count }));

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
    const attendanceRate = totalJoiners > 0 ? Math.round((checkedInCount / totalJoiners) * 100) : 0;

    return {
      totalJoiners,
      checkedInCount,
      attendanceRate,
      joinersOverTime,
      checkInsByHour,
    };
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
    const e = await this.prisma.cleanupEvent.create({
      data: {
        siteId: dto.siteId,
        scheduledAt: new Date(dto.scheduledAt),
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
    } else {
      this.cleanupEventsSse.emitCleanupEventCreated(e.id, {
        moderationStatus: status,
        lifecycleStatus,
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
    return out;
  }
}
