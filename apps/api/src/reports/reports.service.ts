import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, Report, ReportStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { distanceInMeters } from '../common/utils/distance';
import { CreateReportDto } from './dto/create-report.dto';
import {
  AdminReportDetailDto,
  AdminReportListItemDto,
  AdminReportListResponseDto,
} from './dto/admin-report.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';

const ALLOWED_REPORT_STATUS_TRANSITIONS: Record<ReportStatus, ReportStatus[]> = {
  NEW: ['IN_REVIEW', 'APPROVED', 'DELETED'],
  IN_REVIEW: ['APPROVED', 'DELETED'],
  APPROVED: ['DELETED'],
  DELETED: [],
};

const DUPLICATE_RADIUS_METERS = 30;

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  private buildReportNumber(report: { id: string; createdAt: Date }): string {
    const shortId = report.id.slice(0, 4).toUpperCase();
    const yearSuffix = report.createdAt.getFullYear().toString().slice(-2);
    return `R-${yearSuffix}-${shortId}`;
  }

  private buildLocationLabel(site: {
    latitude: number;
    longitude: number;
    description: string | null;
  }): string {
    if (site.description && site.description.trim().length > 0) {
      return site.description;
    }

    const lat = site.latitude.toFixed(4);
    const lng = site.longitude.toFixed(4);
    return `${lat}, ${lng}`;
  }

  private derivePriority(status: ReportStatus): AdminReportDetailDto['priority'] {
    if (status === 'NEW') {
      return 'HIGH';
    }

    if (status === 'IN_REVIEW') {
      return 'MEDIUM';
    }

    if (status === 'APPROVED') {
      return 'LOW';
    }

    return 'LOW';
  }

  async create(dto: CreateReportDto): Promise<Report> {
    const site = await this.prisma.site.findUnique({
      where: { id: dto.siteId },
      select: {
        id: true,
        latitude: true,
        longitude: true,
      },
    });

    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Cannot create report. Site with id '${dto.siteId}' was not found`,
      });
    }

    const metersPerDegreeLat = 111_320;
    const deltaLat = DUPLICATE_RADIUS_METERS / metersPerDegreeLat;
    const metersPerDegreeLng =
      Math.cos((site.latitude * Math.PI) / 180) * metersPerDegreeLat || metersPerDegreeLat;
    const deltaLng = DUPLICATE_RADIUS_METERS / metersPerDegreeLng;

    const candidateReports = await this.prisma.report.findMany({
      where: {
        site: {
          latitude: {
            gte: site.latitude - deltaLat,
            lte: site.latitude + deltaLat,
          },
          longitude: {
            gte: site.longitude - deltaLng,
            lte: site.longitude + deltaLng,
          },
        },
      },
      include: {
        site: {
          select: {
            latitude: true,
            longitude: true,
          },
        },
      },
    });

    const nearbyReports = candidateReports.filter((report) => {
      const distance = distanceInMeters(
        site.latitude,
        site.longitude,
        report.site.latitude,
        report.site.longitude,
      );

      return distance <= DUPLICATE_RADIUS_METERS;
    });

    const primaryReport =
      nearbyReports.length > 0
        ? nearbyReports.reduce((earliest, current) =>
            current.createdAt < earliest.createdAt ? current : earliest,
          )
        : null;

    const potentialDuplicateOfId = primaryReport ? primaryReport.id : null;

    return this.prisma.$transaction(async (tx) => {
      const newReport = await tx.report.create({
        data: {
          siteId: dto.siteId,
          description: dto.description ?? null,
          mediaUrls: dto.mediaUrls ?? [],
          reporterId: dto.reporterId ?? null,
          potentialDuplicateOfId,
        },
      });

      if (
        primaryReport &&
        dto.reporterId &&
        primaryReport.reporterId &&
        dto.reporterId !== primaryReport.reporterId
      ) {
        await tx.reportCoReporter.upsert({
          where: {
            reportId_userId: {
              reportId: primaryReport.id,
              userId: dto.reporterId,
            },
          },
          update: {},
          create: {
            reportId: primaryReport.id,
            userId: dto.reporterId,
          },
        });
      }

      return newReport;
    });
  }

  async findAllForModeration(query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    const where: Prisma.ReportWhereInput = {
      ...(query.status ? { status: query.status } : {}),
      ...(query.siteId ? { siteId: query.siteId } : {}),
    };

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
              id: true,
              status: true,
              latitude: true,
              longitude: true,
              description: true,
            },
          },
          coReporters: true,
          potentialDuplicates: {
            select: { id: true },
          },
        },
      }),
      this.prisma.report.count({ where }),
    ]);

    const items: AdminReportListItemDto[] = data.map((report) => ({
      id: report.id,
      reportNumber: this.buildReportNumber(report),
      name: report.site.description ?? 'Reported site',
      location: report.site ? this.buildLocationLabel(report.site) : 'Unknown location',
      dateReportedAt: report.createdAt.toISOString(),
      status: report.status,
      isPotentialDuplicate:
        report.potentialDuplicateOfId !== null || report.potentialDuplicates.length > 0,
      coReporterCount: report.coReporters.length,
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

  async updateStatus(
    reportId: string,
    dto: UpdateReportStatusDto,
    moderator: AuthenticatedUser,
  ): Promise<Report> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: { id: true, status: true },
    });

    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    if (report.status === dto.status) {
      return this.prisma.report.findUniqueOrThrow({
        where: { id: reportId },
      });
    }

    const allowedStatuses = ALLOWED_REPORT_STATUS_TRANSITIONS[report.status];
    if (!allowedStatuses.includes(dto.status)) {
      throw new BadRequestException({
        code: 'INVALID_REPORT_STATUS_TRANSITION',
        message: `Cannot transition report status from '${report.status}' to '${dto.status}'`,
        details: {
          from: report.status,
          to: dto.status,
          allowedTo: allowedStatuses,
        },
      });
    }

    const now = new Date();

    return this.prisma.report.update({
      where: { id: reportId },
      data: {
        status: dto.status,
        moderatedAt: now,
        moderationReason: dto.reason ?? null,
        moderatedById: moderator.userId,
      },
    });
  }

  async findOneForModeration(reportId: string): Promise<AdminReportDetailDto> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      include: {
        site: true,
        reporter: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        moderatedBy: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        coReporters: {
          include: {
            user: {
              select: {
                firstName: true,
                lastName: true,
              },
            },
          },
        },
        potentialDuplicateOf: {
          select: {
            id: true,
            createdAt: true,
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

    const reportNumber = this.buildReportNumber(report);
    const locationLabel = this.buildLocationLabel(report.site);

    const reporterAlias = report.reporter
      ? `${report.reporter.firstName} ${report.reporter.lastName}`.trim()
      : 'Anonymous reporter';

    const moderationQueueLabel = 'General Queue';
    const moderationAssignedTeam = 'City Moderation';
    const moderationSlaLabel =
      report.status === 'NEW' ? '4h remaining' : report.status === 'IN_REVIEW' ? '2h remaining' : 'Completed';

    const evidence = report.mediaUrls.map((url, index) => ({
      id: `ev-${index + 1}`,
      label: `Evidence ${index + 1}`,
      kind: 'image' as const,
      sizeLabel: '—',
      uploadedAt: report.createdAt.toISOString(),
      previewUrl: url,
      previewAlt: `Evidence ${index + 1} for report ${reportNumber}`,
    }));

    const timeline = [
      {
        id: 'tl-submitted',
        title: 'Report submitted',
        detail: 'Initial report created with location and optional media evidence.',
        actor: reporterAlias,
        occurredAt: report.createdAt.toISOString(),
        tone: 'info' as const,
      },
      ...(report.moderatedAt
        ? [
            {
              id: 'tl-moderated',
              title:
                report.status === 'APPROVED'
                  ? 'Report approved'
                  : report.status === 'DELETED'
                    ? 'Report rejected'
                    : 'Report updated',
              detail:
                report.moderationReason ??
                (report.status === 'APPROVED'
                  ? 'Report was approved after moderation review.'
                  : 'Report was updated during moderation review.'),
              actor: report.moderatedBy
                ? `${report.moderatedBy.firstName} ${report.moderatedBy.lastName}`.trim()
                : 'Moderator',
              occurredAt: report.moderatedAt.toISOString(),
              tone:
                report.status === 'APPROVED'
                  ? ('success' as const)
                  : report.status === 'DELETED'
                    ? ('warning' as const)
                    : ('neutral' as const),
            },
          ]
        : []),
    ];

    const coReporters: string[] = report.coReporters
      .map((coReporter) =>
        coReporter.user
          ? `${coReporter.user.firstName} ${coReporter.user.lastName}`.trim()
          : null,
      )
      .filter((alias): alias is string => !!alias);

    const isPotentialDuplicate =
      report.potentialDuplicateOfId !== null || coReporters.length > 0;

    const potentialDuplicateOfReportNumber = report.potentialDuplicateOf
      ? this.buildReportNumber(report.potentialDuplicateOf)
      : null;

    return {
      id: report.id,
      reportNumber,
      status: report.status,
      priority: this.derivePriority(report.status),
      title: report.site.description ?? 'Reported site',
      description: report.description ?? 'No description was provided for this report.',
      location: locationLabel,
      submittedAt: report.createdAt.toISOString(),
      reporterAlias,
      reporterTrust: 'Bronze',
      evidence,
      timeline,
      moderation: {
        queueLabel: moderationQueueLabel,
        slaLabel: moderationSlaLabel,
        assignedTeam: moderationAssignedTeam,
      },
      mapPin: {
        latitude: report.site.latitude,
        longitude: report.site.longitude,
        label: locationLabel,
      },
      isPotentialDuplicate,
      coReporters,
      potentialDuplicateOfReportNumber,
    };
  }
}
