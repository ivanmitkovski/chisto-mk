import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { CleanupEventStatus, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import { CreateCleanupEventDto } from './dto/create-cleanup-event.dto';
import { PatchCleanupEventDto } from './dto/patch-cleanup-event.dto';
import { ListCleanupEventsQueryDto } from './dto/list-cleanup-events-query.dto';

@Injectable()
export class CleanupEventsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async list(query: ListCleanupEventsQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: Prisma.CleanupEventWhereInput = {};
    if (query.status === 'upcoming') {
      where.completedAt = { equals: null };
    } else if (query.status === 'completed') {
      where.completedAt = { not: null };
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
        include: {
          site: {
            select: {
              id: true,
              latitude: true,
              longitude: true,
              description: true,
              status: true,
            },
          },
        },
      }),
      this.prisma.cleanupEvent.count({ where }),
    ]);

    return {
      data: rows.map((e) => ({
        id: e.id,
        siteId: e.siteId,
        scheduledAt: e.scheduledAt.toISOString(),
        completedAt: e.completedAt?.toISOString() ?? null,
        organizerId: e.organizerId,
        participantCount: e.participantCount,
        status: e.status,
        site: e.site,
      })),
      meta: { page, limit, total },
    };
  }

  async findOne(id: string) {
    const e = await this.prisma.cleanupEvent.findUnique({
      where: { id },
      include: {
        site: true,
      },
    });
    if (!e) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOT_FOUND',
        message: 'Cleanup event not found',
      });
    }
    return {
      id: e.id,
      siteId: e.siteId,
      scheduledAt: e.scheduledAt.toISOString(),
      completedAt: e.completedAt?.toISOString() ?? null,
      organizerId: e.organizerId,
      participantCount: e.participantCount,
      status: e.status,
      site: e.site,
    };
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
    const e = await this.prisma.cleanupEvent.create({
      data: {
        siteId: dto.siteId,
        scheduledAt: new Date(dto.scheduledAt),
        completedAt: dto.completedAt ? new Date(dto.completedAt) : null,
        organizerId: dto.organizerId ?? null,
        participantCount: dto.participantCount ?? 0,
        status, // Default APPROVED for admin, PENDING when status explicitly passed (e.g. user-created)
      },
    });

    await this.audit.log({
      actorId: actor.userId,
      action: 'CLEANUP_EVENT_CREATED',
      resourceType: 'CleanupEvent',
      resourceId: e.id,
    });

    return this.findOne(e.id);
  }

  async patch(id: string, dto: PatchCleanupEventDto, actor: AuthenticatedUser) {
    const existing = await this.prisma.cleanupEvent.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOT_FOUND',
        message: 'Cleanup event not found',
      });
    }

    const data: {
      scheduledAt?: Date;
      completedAt?: Date | null;
      participantCount?: number;
      status?: CleanupEventStatus;
    } = {};
    if (dto.scheduledAt != null) {
      data.scheduledAt = new Date(dto.scheduledAt);
    }
    if (dto.completedAt !== undefined) {
      data.completedAt = dto.completedAt ? new Date(dto.completedAt) : null;
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

    await this.prisma.cleanupEvent.update({
      where: { id },
      data,
    });

    const auditAction =
      data.status === CleanupEventStatus.APPROVED
        ? 'CLEANUP_EVENT_APPROVED'
        : data.status === CleanupEventStatus.DECLINED
          ? 'CLEANUP_EVENT_DECLINED'
          : 'CLEANUP_EVENT_UPDATED';
    await this.audit.log({
      actorId: actor.userId,
      action: auditAction,
      resourceType: 'CleanupEvent',
      resourceId: id,
      metadata: JSON.parse(JSON.stringify(dto)) as Prisma.InputJsonValue,
    });

    return this.findOne(id);
  }
}
