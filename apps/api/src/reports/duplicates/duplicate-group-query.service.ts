import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, ReportStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  AdminDuplicateReportItemDto,
} from '../dto/admin-duplicate-report.dto';
import { ListReportsQueryDto } from '../dto/list-reports-query.dto';
import {
  displayReportTitle,
  getReportNumber,
  listLocationLabel,
} from '../report-copy.helpers';

@Injectable()
export class DuplicateGroupQueryService {
  constructor(private readonly prisma: PrismaService) {}

  async findPrimaryReportId(reportId: string): Promise<string> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: { id: true, potentialDuplicateOfId: true },
    });

    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    return report.potentialDuplicateOfId ?? report.id;
  }

  private buildDuplicateReportItem(report: {
    id: string;
    createdAt: Date;
    status: ReportStatus;
    title: string;
    description: string | null;
    category: string | null;
    mediaUrls: string[];
    site: {
      latitude: number;
      longitude: number;
      description: string | null;
      address: string | null;
    };
    coReporters: { id: string }[];
  }): AdminDuplicateReportItemDto {
    return {
      id: report.id,
      reportNumber: getReportNumber(report),
      title: displayReportTitle(report),
      location: listLocationLabel(report.site, report.description),
      submittedAt: report.createdAt.toISOString(),
      status: report.status,
      coReporterCount: report.coReporters.length,
      mediaCount: report.mediaUrls.length,
    };
  }

  private buildDuplicateGroupQuery(query: ListReportsQueryDto): Prisma.ReportWhereInput {
    const statusOrSiteFilters: Prisma.ReportWhereInput[] = [];
    if (query.status) {
      statusOrSiteFilters.push({
        OR: [{ status: query.status }, { potentialDuplicates: { some: { status: query.status } } }],
      });
    }

    if (query.siteId) {
      statusOrSiteFilters.push({
        OR: [{ siteId: query.siteId }, { potentialDuplicates: { some: { siteId: query.siteId } } }],
      });
    }

    return {
      potentialDuplicateOfId: null,
      status: { not: 'DELETED' },
      potentialDuplicates: { some: {} },
      ...(statusOrSiteFilters.length > 0 ? { AND: statusOrSiteFilters } : {}),
    };
  }

  async findDuplicateGroups(query: ListReportsQueryDto): Promise<AdminDuplicateReportGroupsResponseDto> {
    const where = this.buildDuplicateGroupQuery(query);
    const skip = (query.page - 1) * query.limit;

    const [data, total] = await this.prisma.$transaction([
      this.prisma.report.findMany({
        where,
        skip,
        take: query.limit,
        orderBy: { createdAt: 'desc' },
        include: {
          site: {
            select: {
              latitude: true,
              longitude: true,
              description: true,
              address: true,
            },
          },
          coReporters: {
            select: {
              id: true,
            },
          },
          potentialDuplicates: {
            orderBy: { createdAt: 'asc' },
            include: {
              site: {
                select: {
                  latitude: true,
                  longitude: true,
                  description: true,
                  address: true,
                },
              },
              coReporters: {
                select: {
                  id: true,
                },
              },
            },
          },
        },
      }),
      this.prisma.report.count({ where }),
    ]);

    const groups: AdminDuplicateReportGroupDto[] = data.map((primaryReport) => ({
      primaryReport: this.buildDuplicateReportItem(primaryReport),
      duplicateReports: primaryReport.potentialDuplicates.map((duplicateReport) =>
        this.buildDuplicateReportItem(duplicateReport),
      ),
      totalReports: primaryReport.potentialDuplicates.length + 1,
    }));

    return {
      data: groups,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
      },
    };
  }

  async findDuplicateGroupByReport(reportId: string): Promise<AdminDuplicateReportGroupDto> {
    const primaryReportId = await this.findPrimaryReportId(reportId);

    const primaryReport = await this.prisma.report.findUnique({
      where: { id: primaryReportId },
      include: {
        site: {
          select: {
            latitude: true,
            longitude: true,
            description: true,
            address: true,
          },
        },
        coReporters: {
          select: {
            id: true,
          },
        },
        potentialDuplicates: {
          orderBy: { createdAt: 'asc' },
          include: {
            site: {
              select: {
                latitude: true,
                longitude: true,
                description: true,
                address: true,
              },
            },
            coReporters: {
              select: {
                id: true,
              },
            },
          },
        },
      },
    });

    if (!primaryReport) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    return {
      primaryReport: this.buildDuplicateReportItem(primaryReport),
      duplicateReports: primaryReport.potentialDuplicates.map((duplicateReport) =>
        this.buildDuplicateReportItem(duplicateReport),
      ),
      totalReports: primaryReport.potentialDuplicates.length + 1,
    };
  }
}
