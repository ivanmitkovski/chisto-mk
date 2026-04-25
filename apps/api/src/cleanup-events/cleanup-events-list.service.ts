import { Injectable, NotFoundException } from '@nestjs/common';
import { CleanupEventStatus, EcoEventLifecycleStatus, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { ListCleanupEventsQueryDto } from './dto/list-cleanup-events-query.dto';

@Injectable()
export class CleanupEventsListService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploads: ReportsUploadService,
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
}
