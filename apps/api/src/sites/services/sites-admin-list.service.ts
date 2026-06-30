import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { ListAdminSitesQueryDto } from '../dto/list-admin-sites-query.dto';

@Injectable()
export class SitesAdminListService {
  constructor(private readonly prisma: PrismaService) {}

  async list(query: ListAdminSitesQueryDto): Promise<{
    data: Array<{
      id: string;
      latitude: number;
      longitude: number;
      description: string | null;
      status: string;
      createdAt: string;
      reportCount: number;
    }>;
    meta: { page: number; limit: number; total: number };
  }> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: Prisma.SiteWhereInput = {};
    if (query.status) {
      where.status = query.status;
    }
    if (query.search?.trim()) {
      const q = query.search.trim();
      where.OR = [
        { id: { contains: q, mode: 'insensitive' } },
        { description: { contains: q, mode: 'insensitive' } },
      ];
    }

    const [rows, total] = await this.prisma.$transaction([
      this.prisma.site.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        select: {
          id: true,
          latitude: true,
          longitude: true,
          description: true,
          status: true,
          createdAt: true,
          _count: { select: { reports: true } },
        },
      }),
      this.prisma.site.count({ where }),
    ]);

    return {
      data: rows.map((row) => ({
        id: row.id,
        latitude: row.latitude,
        longitude: row.longitude,
        description: row.description,
        status: row.status,
        createdAt: row.createdAt.toISOString(),
        reportCount: row._count.reports,
      })),
      meta: { page, limit, total },
    };
  }
}
