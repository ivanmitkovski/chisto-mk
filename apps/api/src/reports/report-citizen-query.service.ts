import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ListMyReportsQueryDto } from './dto/list-my-reports-query.dto';
import { CitizenReportDetailDto } from './dto/citizen-report-detail.dto';
import { UserReportListItemDto, UserReportViewerRole } from './dto/user-report.dto';
import { ReportsUploadService } from './reports-upload.service';
import { signPublicMediaUrlsDeduped } from '../storage/batch-private-object-sign';
import {
  displayReportTitle,
  getReportNumber,
  listLocationLabel,
  optionalReportNarrative,
} from './report-copy.helpers';

@Injectable()
export class ReportCitizenQueryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  async findForCurrentUser(
    user: AuthenticatedUser,
    query: ListMyReportsQueryDto,
  ): Promise<{
    data: UserReportListItemDto[];
    total: number;
    page: number;
    limit: number;
  }> {
    const where: Prisma.ReportWhereInput = {
      OR: [{ reporterId: user.userId }, { coReporters: { some: { userId: user.userId } } }],
    };
    const skip = (query.page - 1) * query.limit;

    const [reports, total] = await this.prisma.$transaction([
      this.prisma.report.findMany({
        where,
        skip,
        take: query.limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          createdAt: true,
          reporterId: true,
          title: true,
          description: true,
          category: true,
          status: true,
          mediaUrls: true,
          severity: true,
          cleanupEffort: true,
          potentialDuplicateOfId: true,
          reportNumber: true,
          site: {
            select: {
              latitude: true,
              longitude: true,
              description: true,
              address: true,
            },
          },
          coReporters: { select: { userId: true } },
          potentialDuplicateOf: {
            select: {
              id: true,
              createdAt: true,
            },
          },
          potentialDuplicates: {
            select: {
              id: true,
            },
          },
        },
      }),
      this.prisma.report.count({ where }),
    ]);

    const reportIds = reports.map((r) => r.id);
    const pointTxns = await this.prisma.pointTransaction.findMany({
      where: {
        referenceType: 'Report',
        referenceId: { in: reportIds },
      },
      select: { referenceId: true, delta: true },
    });
    const pointsByReport = new Map<string, number>();
    for (const t of pointTxns) {
      if (t.referenceId) {
        pointsByReport.set(t.referenceId, (pointsByReport.get(t.referenceId) ?? 0) + t.delta);
      }
    }

    const flatMedia: string[] = [];
    for (const report of reports) {
      for (const u of report.mediaUrls ?? []) {
        if (typeof u === 'string' && u.trim().length > 0) {
          flatMedia.push(u.trim());
        }
      }
    }
    const mediaUrlByOriginal = await signPublicMediaUrlsDeduped(flatMedia, (urls) =>
      this.reportsUploadService.signUrls(urls),
    );

    const data = reports.map((report) => {
      const signedUrls =
        report.mediaUrls?.length > 0
          ? report.mediaUrls.map((u) => {
              const t = typeof u === 'string' ? u.trim() : '';
              if (t.length === 0) return u;
              return mediaUrlByOriginal.get(t) ?? u;
            })
          : [];
      const viewerRole: UserReportViewerRole =
        report.reporterId === user.userId ? 'primary' : 'co_reporter';
      const pointsTotal = pointsByReport.get(report.id) ?? 0;
      return {
        id: report.id,
        reportNumber: getReportNumber(report),
        title: displayReportTitle(report),
        description: optionalReportNarrative(report.description, report.category),
        location: listLocationLabel(report.site, report.description),
        submittedAt: report.createdAt.toISOString(),
        status: report.status,
        isPotentialDuplicate:
          report.potentialDuplicateOfId !== null ||
          report.potentialDuplicates.length > 0 ||
          report.coReporters.length > 0,
        coReporterCount: report.coReporters.length,
        mediaUrls: signedUrls,
        pointsAwarded: viewerRole === 'primary' ? pointsTotal : 0,
        category: report.category ?? null,
        severity: report.severity ?? null,
        cleanupEffort: report.cleanupEffort ?? null,
        viewerRole,
      };
    });

    return {
      data,
      total,
      page: query.page,
      limit: query.limit,
    };
  }

  async findOneForCitizen(
    reportId: string,
    user: AuthenticatedUser,
  ): Promise<CitizenReportDetailDto> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        createdAt: true,
        reporterId: true,
        title: true,
        description: true,
        category: true,
        status: true,
        mediaUrls: true,
        severity: true,
        cleanupEffort: true,
        reportNumber: true,
        site: {
          select: {
            id: true,
            latitude: true,
            longitude: true,
            description: true,
            address: true,
          },
        },
        reporter: {
          select: { firstName: true, lastName: true },
        },
        coReporters: {
          select: {
            userId: true,
            user: {
              select: { firstName: true, lastName: true },
            },
          },
        },
      },
    });

    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    const isPrimaryReporter = report.reporterId === user.userId;
    const isCoReporter = report.coReporters.some((cr) => cr.userId === user.userId);
    if (!isPrimaryReporter && !isCoReporter) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    const viewerRole: UserReportViewerRole = isPrimaryReporter ? 'primary' : 'co_reporter';

    const reporterName = report.reporter
      ? `${report.reporter.firstName} ${report.reporter.lastName}`.trim()
      : null;
    const coReporterNames = report.coReporters
      .map((cr) =>
        cr.user ? `${cr.user.firstName} ${cr.user.lastName}`.trim() : null,
      )
      .filter((n): n is string => !!n);

    const mediaUrls = await this.reportsUploadService.signUrls(report.mediaUrls);
    let pointsAwarded = 0;
    if (viewerRole === 'primary') {
      const pointTxns = await this.prisma.pointTransaction.findMany({
        where: { referenceType: 'Report', referenceId: reportId },
        select: { delta: true },
      });
      pointsAwarded = pointTxns.reduce((sum, t) => sum + t.delta, 0);
    }

    return {
      id: report.id,
      reportNumber: getReportNumber(report),
      status: report.status,
      title: displayReportTitle(report),
      description: optionalReportNarrative(report.description, report.category),
      mediaUrls,
      submittedAt: report.createdAt.toISOString(),
      site: {
        id: report.site.id,
        latitude: report.site.latitude,
        longitude: report.site.longitude,
        description: report.site.description,
        address: report.site.address,
      },
      reporterName,
      coReporterNames,
      location: listLocationLabel(report.site, report.description),
      pointsAwarded,
      category: report.category ?? null,
      severity: report.severity ?? null,
      cleanupEffort: report.cleanupEffort ?? null,
      viewerRole,
    };
  }
}
