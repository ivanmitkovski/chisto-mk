import { Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async log(params: {
    actorId: string | null;
    action: string;
    resourceType: string;
    resourceId?: string | null;
    metadata?: Prisma.InputJsonValue;
    ipAddress?: string | null;
  }): Promise<void> {
    await this.prisma.auditLog.create({
      data: {
        actorId: params.actorId,
        action: params.action,
        resourceType: params.resourceType,
        resourceId: params.resourceId ?? null,
        ...(params.metadata !== undefined ? { metadata: params.metadata } : {}),
        ipAddress: params.ipAddress ?? null,
      },
    });
  }

  async listForAdmin(query: {
    page: number;
    limit: number;
    action?: string;
    resourceType?: string;
    resourceId?: string;
    actorId?: string;
    from?: Date;
    to?: Date;
  }): Promise<{
    data: Array<{
      id: string;
      createdAt: string;
      action: string;
      resourceType: string;
      resourceId: string | null;
      actorEmail: string | null;
      metadata: unknown;
    }>;
    meta: { page: number; limit: number; total: number };
  }> {
    const skip = (query.page - 1) * query.limit;
    const where: Prisma.AuditLogWhereInput = {};
    if (query.action) {
      where.action = query.action;
    }
    if (query.resourceType) {
      where.resourceType = query.resourceType;
    }
    if (query.resourceId) {
      where.resourceId = query.resourceId;
    }
    if (query.actorId) {
      where.actorId = query.actorId;
    }
    if (query.from || query.to) {
      where.createdAt = {};
      if (query.from) {
        where.createdAt.gte = query.from;
      }
      if (query.to) {
        where.createdAt.lte = query.to;
      }
    }

    const [rows, total] = await this.prisma.$transaction([
      this.prisma.auditLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: query.limit,
        include: {
          actor: {
            select: { email: true },
          },
        },
      }),
      this.prisma.auditLog.count({ where }),
    ]);

    return {
      data: rows.map((r) => ({
        id: r.id,
        createdAt: r.createdAt.toISOString(),
        action: r.action,
        resourceType: r.resourceType,
        resourceId: r.resourceId,
        actorEmail: r.actor?.email ?? null,
        metadata: r.metadata,
      })),
      meta: {
        page: query.page,
        limit: query.limit,
        total,
      },
    };
  }

  async listForUser(
    userId: string,
    query: { page: number; limit: number },
  ): Promise<{
    data: Array<{
      id: string;
      createdAt: string;
      action: string;
      resourceType: string;
      resourceId: string | null;
      actorEmail: string | null;
      metadata: unknown;
    }>;
    meta: { page: number; limit: number; total: number };
  }> {
    const skip = (query.page - 1) * query.limit;
    const where: Prisma.AuditLogWhereInput = {
      OR: [
        { actorId: userId },
        { resourceType: 'User', resourceId: userId },
      ],
    };

    const [rows, total] = await this.prisma.$transaction([
      this.prisma.auditLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: query.limit,
        include: {
          actor: {
            select: { email: true },
          },
        },
      }),
      this.prisma.auditLog.count({ where }),
    ]);

    return {
      data: rows.map((r) => ({
        id: r.id,
        createdAt: r.createdAt.toISOString(),
        action: r.action,
        resourceType: r.resourceType,
        resourceId: r.resourceId,
        actorEmail: r.actor?.email ?? null,
        metadata: r.metadata,
      })),
      meta: {
        page: query.page,
        limit: query.limit,
        total,
      },
    };
  }

  async recentForUser(userId: string, take: number): Promise<
    Array<{
      id: string;
      title: string;
      detail: string;
      occurredAtLabel: string;
      tone: 'success' | 'warning' | 'info';
      icon: string;
    }>
  > {
    const logs = await this.prisma.auditLog.findMany({
      where: { actorId: userId },
      orderBy: { createdAt: 'desc' },
      take,
    });

    return logs.map((log) => {
      const tone: 'success' | 'warning' | 'info' =
        log.action.includes('FAILED') || log.action.includes('REJECT') ? 'warning' : 'info';
      return {
        id: log.id,
        title: log.action.replace(/_/g, ' '),
        detail: `${log.resourceType}${log.resourceId ? ` · ${log.resourceId}` : ''}`,
        occurredAtLabel: log.createdAt.toISOString(),
        tone,
        icon: 'shield',
      };
    });
  }
}
