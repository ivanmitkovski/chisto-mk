import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import {
  AdminReportListItemDto,
  AdminReportListResponseDto,
} from '../dto/admin-report.dto';
import { ListReportsQueryDto } from '../dto/list-reports-query.dto';
import { AdminReportsQueueSummaryDto } from '../dto/admin-reports-queue-summary.dto';
import { reportCleanupEffortLabel } from '../util/report-cleanup-effort';
import {
  displayReportTitle,
  getReportNumber,
  listLocationLabel,
} from '../util/report-copy.helpers';

@Injectable()
export class ReportsModerationListService {
  constructor(private readonly prisma: PrismaService) {}

  async findAllForModeration(query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    const searchTerm = (query.search ?? query.q)?.trim();
    const and: Prisma.ReportWhereInput[] = [];

    if (query.status) {
      and.push({ status: query.status });
    }
    if (query.siteId) {
      and.push({ siteId: query.siteId });
    }
    if (query.duplicatesOnly) {
      and.push({
        OR: [{ potentialDuplicateOfId: { not: null } }, { potentialDuplicates: { some: {} } }],
      });
    }
    if (searchTerm) {
      and.push({
        OR: [
          { title: { contains: searchTerm, mode: 'insensitive' } },
          { description: { contains: searchTerm, mode: 'insensitive' } },
          { reportNumber: { contains: searchTerm, mode: 'insensitive' } },
          { site: { address: { contains: searchTerm, mode: 'insensitive' } } },
          { site: { description: { contains: searchTerm, mode: 'insensitive' } } },
        ],
      });
    }

    const where: Prisma.ReportWhereInput = and.length > 0 ? { AND: and } : {};

    const sortField = query.sort ?? 'dateReportedAt';
    const sortDir = query.dir === 'asc' ? 'asc' : 'desc';
    const orderBy: Prisma.ReportOrderByWithRelationInput =
      sortField === 'reportNumber'
        ? { reportNumber: sortDir }
        : sortField === 'name'
          ? { title: sortDir }
          : sortField === 'status'
            ? { status: sortDir }
            : { createdAt: sortDir };

    const skip = (query.page - 1) * query.limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.report.findMany({
        where,
        skip,
        take: query.limit,
        orderBy,
        select: {
          id: true,
          createdAt: true,
          reportNumber: true,
          title: true,
          description: true,
          category: true,
          status: true,
          cleanupEffort: true,
          potentialDuplicateOfId: true,
          site: {
            select: {
              id: true,
              status: true,
              latitude: true,
              longitude: true,
              description: true,
              address: true,
            },
          },
          coReporters: { select: { userId: true } },
          potentialDuplicates: {
            select: { id: true },
          },
        },
      }),
      this.prisma.report.count({ where }),
    ]);

    const items: AdminReportListItemDto[] = data.map((report) => ({
      id: report.id,
      reportNumber: getReportNumber(report),
      name: displayReportTitle(report),
      location: report.site
        ? listLocationLabel(report.site, report.description)
        : 'Unknown location',
      dateReportedAt: report.createdAt.toISOString(),
      status: report.status,
      isPotentialDuplicate:
        report.potentialDuplicateOfId !== null || report.potentialDuplicates.length > 0,
      coReporterCount: report.coReporters.length,
      cleanupEffortLabel: reportCleanupEffortLabel(report.cleanupEffort),
    }));

    return {
      data: items,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
      },
    };
  }

  async getQueueSummary(): Promise<AdminReportsQueueSummaryDto> {
    const [total, needAttentionCount, duplicatesCount, grouped] = await this.prisma.$transaction([
      this.prisma.report.count(),
      this.prisma.report.count({
        where: { status: { in: ['NEW', 'IN_REVIEW'] } },
      }),
      this.prisma.report.count({
        where: {
          OR: [{ potentialDuplicateOfId: { not: null } }, { potentialDuplicates: { some: {} } }],
        },
      }),
      this.prisma.report.groupBy({
        by: ['status'],
        _count: { _all: true },
        orderBy: { status: 'asc' },
      }),
    ]);

    const byStatus = grouped.reduce<Record<string, number>>((acc, row) => {
      acc[row.status] = typeof row._count === 'object' && row._count ? (row._count._all ?? 0) : 0;
      return acc;
    }, {});

    return {
      total,
      needAttentionCount,
      duplicatesCount,
      byStatus,
    };
  }
}
