import { Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import {
  AdminReportListItemDto,
  AdminReportListResponseDto,
} from './dto/admin-report.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { reportCleanupEffortLabel } from './report-cleanup-effort';
import {
  displayReportTitle,
  getReportNumber,
  listLocationLabel,
} from './report-copy.helpers';

@Injectable()
export class ReportsModerationListService {
  constructor(private readonly prisma: PrismaService) {}

  async findAllForModeration(query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    const where: Prisma.ReportWhereInput = {
      ...(query.status ? { status: query.status } : {}),
      ...(query.siteId ? { siteId: query.siteId } : {}),
      ...(query.duplicatesOnly
        ? {
            OR: [{ potentialDuplicateOfId: { not: null } }, { potentialDuplicates: { some: {} } }],
          }
        : {}),
    };

    const skip = (query.page - 1) * query.limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.report.findMany({
        where,
        skip,
        take: query.limit,
        orderBy: { createdAt: 'desc' },
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
}
