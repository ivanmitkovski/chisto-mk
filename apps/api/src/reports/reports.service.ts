import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import {
  AdminNotificationCategory,
  AdminNotificationTone,
  Prisma,
  Report,
  ReportCleanupEffort,
  SiteStatus,
} from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';
import { assertReportVisibleToUser } from '../common/helpers/assert-ownership.helper';
import { distanceInMeters } from '../common/utils/distance';
import { CreateReportDto } from './dto/create-report.dto';
import { CreateReportWithLocationDto } from './dto/create-report-with-location.dto';
import { ReportSubmitResponseDto } from './dto/report-submit-response.dto';
import { AdminReportDetailDto, AdminReportListResponseDto } from './dto/admin-report.dto';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  MergeDuplicateReportsDto,
  MergeDuplicateReportsResponseDto,
} from './dto/admin-duplicate-report.dto';
import { ListMyReportsQueryDto } from './dto/list-my-reports-query.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { ReportCapacityDto } from './dto/report-capacity.dto';
import { ReportCapacityService } from './report-capacity.service';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { CitizenReportDetailDto } from './dto/citizen-report-detail.dto';
import { UserReportListItemDto } from './dto/user-report.dto';
import { ReportsUploadService } from './reports-upload.service';
import { NotificationEventsService } from '../admin-events/notification-events.service';
import { ReportEventsService } from '../admin-events/report-events.service';
import { SiteEventsService } from '../admin-events/site-events.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import { parseReportCleanupEffort } from './report-cleanup-effort';
import { DUPLICATE_RADIUS_METERS, SITE_NEARBY_RADIUS_METERS } from './reports.constants';
import {
  displayReportTitle,
  getReportNumber,
  listLocationLabel,
  optionalReportNarrative,
} from './report-copy.helpers';
import { ReportsModerationService } from './reports-moderation.service';
import { ReportsDuplicateMergeService } from './reports-duplicate-merge.service';

@Injectable()
export class ReportsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly reportEventsService: ReportEventsService,
    private readonly notificationEventsService: NotificationEventsService,
    private readonly siteEventsService: SiteEventsService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
    private readonly reportCapacity: ReportCapacityService,
    private readonly reportsModeration: ReportsModerationService,
    private readonly reportsDuplicateMerge: ReportsDuplicateMergeService,
  ) {}

  private normalizeIdempotencyKey(header: string | string[] | undefined): string | null {
    if (header === undefined) {
      return null;
    }
    const raw = Array.isArray(header) ? header[0] : header;
    const t = raw.trim();
    if (!t || t.length > 128) {
      return null;
    }
    return t;
  }

  private async resolveIdempotentReportSubmit(
    userId: string,
    key: string,
  ): Promise<ReportSubmitResponseDto | null> {
    const row = await this.prisma.reportSubmitIdempotency.findUnique({
      where: { userId_key: { userId, key } },
      select: { reportId: true },
    });
    if (!row) {
      return null;
    }
    const report = await this.prisma.report.findUnique({
      where: { id: row.reportId },
      select: {
        id: true,
        siteId: true,
        reportNumber: true,
        createdAt: true,
        reporterId: true,
      },
    });
    if (!report || report.reporterId !== userId) {
      return null;
    }
    return {
      reportId: report.id,
      reportNumber: getReportNumber(report),
      siteId: report.siteId,
      isNewSite: false,
      pointsAwarded: 0,
    };
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
          siteId: dto.siteId.trim(),
          title: dto.title.trim(),
          description: dto.description?.trim() || null,
          mediaUrls: dto.mediaUrls ?? [],
          // SECURITY: Reporter identity never taken from request body — use authenticated flows (e.g. createWithLocation) only.
          reporterId: null,
          potentialDuplicateOfId,
        },
      });

      return newReport;
    });
  }

  async createWithLocation(
    user: AuthenticatedUser,
    dto: CreateReportWithLocationDto,
    headerIdempotencyKey?: string | string[],
  ): Promise<ReportSubmitResponseDto> {
    const trimmedIdem = this.normalizeIdempotencyKey(headerIdempotencyKey);
    if (trimmedIdem) {
      const replay = await this.resolveIdempotentReportSubmit(user.userId, trimmedIdem);
      if (replay) {
        return replay;
      }
    }

    const { latitude, longitude, title, description, mediaUrls, category, severity, address } = dto;
    const trimmedAddress = address?.trim() || null;
    const cleanupEffortParsed: ReportCleanupEffort | null = parseReportCleanupEffort(
      dto.cleanupEffort,
    );
    const metersPerDegreeLat = 111_320;
    const deltaLat = SITE_NEARBY_RADIUS_METERS / metersPerDegreeLat;
    const metersPerDegreeLng =
      Math.cos((latitude * Math.PI) / 180) * metersPerDegreeLat || metersPerDegreeLat;
    const deltaLng = SITE_NEARBY_RADIUS_METERS / metersPerDegreeLng;

    const candidateSites = await this.prisma.site.findMany({
      where: {
        latitude: { gte: latitude - deltaLat, lte: latitude + deltaLat },
        longitude: { gte: longitude - deltaLng, lte: longitude + deltaLng },
      },
      include: {
        reports: {
          orderBy: { createdAt: 'asc' },
          take: 1,
          select: { id: true, createdAt: true, reporterId: true },
        },
      },
    });

    const nearbySites = candidateSites.filter((site) => {
      const dist = distanceInMeters(latitude, longitude, site.latitude, site.longitude);
      return dist <= SITE_NEARBY_RADIUS_METERS;
    });

    type EarliestReport = { id: string; createdAt: Date; reporterId: string | null; siteId: string };
    let primaryReport: EarliestReport | null = null;
    for (const site of nearbySites) {
      const firstReport = site.reports[0];
      if (firstReport && (!primaryReport || firstReport.createdAt < primaryReport.createdAt)) {
        primaryReport = {
          id: firstReport.id,
          createdAt: firstReport.createdAt,
          reporterId: firstReport.reporterId,
          siteId: site.id,
        };
      }
    }

    const targetSiteId = primaryReport?.siteId ?? null;

    const result = await this.prisma.$transaction(async (tx) => {
      await this.reportCapacity.spendWithinTransaction(tx, user.userId, new Date());

      let siteId: string;
      let isNewSite: boolean;
      let siteUpdatedAt: Date | null = null;

      if (targetSiteId) {
        siteId = targetSiteId;
        isNewSite = false;
        if (trimmedAddress) {
          await tx.site.updateMany({
            where: { id: targetSiteId, address: null },
            data: { address: trimmedAddress },
          });
        }
      } else {
        const newSite = await tx.site.create({
          data: {
            latitude,
            longitude,
            address: trimmedAddress,
            description: null,
          },
        });
        siteId = newSite.id;
        isNewSite = true;
        siteUpdatedAt = newSite.updatedAt;
      }

      const newReport = await tx.report.create({
        data: {
          siteId,
          title: title.trim(),
          description: description?.trim() || null,
          mediaUrls: mediaUrls ?? [],
          reporterId: user.userId,
          potentialDuplicateOfId: primaryReport?.id ?? null,
          category: category ?? null,
          severity: severity ?? null,
          cleanupEffort: cleanupEffortParsed,
        },
      });

      if (
        primaryReport &&
        primaryReport.reporterId &&
        primaryReport.reporterId !== user.userId
      ) {
        await tx.reportCoReporter.upsert({
          where: {
            reportId_userId: {
              reportId: primaryReport.id,
              userId: user.userId,
            },
          },
          update: {},
          create: {
            reportId: primaryReport.id,
            userId: user.userId,
            reportedAt: newReport.createdAt,
          },
        });
      }

      const reportNumber = getReportNumber(newReport);

      const notification = await tx.adminNotification.create({
        data: {
          title: isNewSite ? 'Пријавено е ново загадувачко место' : 'Додаден е ко-извештај кон постоечко место',
          message: isNewSite
            ? `Извештај ${reportNumber} е поднесен на нова локација.`
            : `Извештај ${reportNumber} е поднесен во близина на постоечко место.`,
          timeLabel: 'Штотуку',
          tone: AdminNotificationTone.info,
          category: AdminNotificationCategory.reports,
          href: `/dashboard/reports?reportId=${newReport.id}`,
          messageTemplateKey: isNewSite ? 'reports.submitted.new_site' : 'reports.submitted.co_report',
          messageTemplateParams: { reportNumber } as Prisma.InputJsonValue,
        },
      });

      if (trimmedIdem) {
        await tx.reportSubmitIdempotency.create({
          data: {
            userId: user.userId,
            key: trimmedIdem,
            reportId: newReport.id,
          },
        });
      }

      return {
        reportId: newReport.id,
        reportNumber: getReportNumber(newReport),
        siteId,
        isNewSite,
        pointsAwarded: 0, // Points awarded when admin approves, not at submit
        siteUpdatedAt,
        notificationId: notification.id,
        notificationTitle: notification.title,
      };
    });

    this.reportEventsService.emitReportCreated(result.reportId);
    this.reportsOwnerEventsService.emit(
      user.userId,
      result.reportId,
      'report_created',
      { kind: 'created' },
    );
    this.notificationEventsService.emitNotificationCreated(
      result.notificationId,
      result.notificationTitle,
    );
    if (result.isNewSite) {
      this.siteEventsService.emitSiteCreated(result.siteId, {
        status: SiteStatus.REPORTED,
        latitude,
        longitude,
        ...(result.siteUpdatedAt != null ? { updatedAt: result.siteUpdatedAt } : {}),
      });
    } else {
      this.siteEventsService.emitSiteUpdated(result.siteId, { kind: 'updated' });
    }
    return {
      reportId: result.reportId,
      reportNumber: result.reportNumber,
      siteId: result.siteId,
      isNewSite: result.isNewSite,
      pointsAwarded: result.pointsAwarded,
    };
  }

  /**
   * Appends media URLs to an existing report. Only the report's reporter or co-reporters may add media.
   * Used by the two-phase submit flow: create report first, then upload photos to avoid S3 orphans.
   */
  async appendMedia(
    reportId: string,
    userId: string,
    urls: string[],
  ): Promise<void> {
    if (!urls || urls.length === 0) {
      return;
    }

    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        reporterId: true,
        mediaUrls: true,
        coReporters: { select: { userId: true } },
      },
    });

    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    const isReporter = report.reporterId === userId;
    const isCoReporter = report.coReporters.some((c) => c.userId === userId);
    if (!isReporter && !isCoReporter) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Only the report creator or co-reporters may add media',
      });
    }

    const existingUrls = report.mediaUrls ?? [];
    const newUrls = [...existingUrls, ...urls];
    if (newUrls.length > 10) {
      throw new BadRequestException({
        code: 'TOO_MANY_MEDIA',
        message: 'Maximum 10 media files per report',
      });
    }

    await this.prisma.report.update({
      where: { id: reportId },
      data: { mediaUrls: newUrls },
    });

    if (report.reporterId) {
      this.reportsOwnerEventsService.emit(
        report.reporterId,
        reportId,
        'report_updated',
        { kind: 'media_appended' },
      );
    }
  }

  async findForCurrentUser(
    user: AuthenticatedUser,
    query: ListMyReportsQueryDto,
  ): Promise<{
    data: UserReportListItemDto[];
    total: number;
    page: number;
    limit: number;
  }> {
    const where = { reporterId: user.userId };
    const skip = (query.page - 1) * query.limit;

    const [reports, total] = await this.prisma.$transaction([
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
          coReporters: true,
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

    const data = await Promise.all(
      reports.map(async (report) => {
        const signedUrls =
          report.mediaUrls?.length > 0
            ? await this.reportsUploadService.signUrls(report.mediaUrls)
            : [];
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
          pointsAwarded: pointsByReport.get(report.id) ?? 0,
          category: report.category ?? null,
          severity: report.severity ?? null,
          cleanupEffort: report.cleanupEffort ?? null,
        };
      }),
    );

    return {
      data,
      total,
      page: query.page,
      limit: query.limit,
    };
  }

  async getCapacityForCurrentUser(user: AuthenticatedUser): Promise<ReportCapacityDto> {
    return this.reportCapacity.getCapacityForCurrentUser(user);
  }

  async findAllForModeration(query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    return this.reportsModeration.findAllForModeration(query);
  }

  async findDuplicateGroups(query: ListReportsQueryDto): Promise<AdminDuplicateReportGroupsResponseDto> {
    return this.reportsDuplicateMerge.findDuplicateGroups(query);
  }

  async findDuplicateGroupByReport(reportId: string): Promise<AdminDuplicateReportGroupDto> {
    return this.reportsDuplicateMerge.findDuplicateGroupByReport(reportId);
  }

  async mergeDuplicateReports(
    reportId: string,
    dto: MergeDuplicateReportsDto,
    moderator: AuthenticatedUser,
  ): Promise<MergeDuplicateReportsResponseDto> {
    return this.reportsDuplicateMerge.mergeDuplicateReports(reportId, dto, moderator);
  }

  async updateStatus(
    reportId: string,
    dto: UpdateReportStatusDto,
    moderator: AuthenticatedUser,
  ): Promise<Report> {
    return this.reportsModeration.updateStatus(reportId, dto, moderator);
  }

  async findOneForModeration(reportId: string): Promise<AdminReportDetailDto> {
    return this.reportsModeration.findOneForModeration(reportId);
  }

  async findOne(
    reportId: string,
    user: AuthenticatedUser,
  ): Promise<AdminReportDetailDto | CitizenReportDetailDto> {
    // SECURITY: Enforce report visibility before branching (moderation vs citizen DTO); co-reporters included; explicit 403 on IDOR probe.
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        reporterId: true,
        coReporters: { select: { userId: true } },
      },
    });
    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }
    const coReporterUserIds = report.coReporters.map((c) => c.userId);
    assertReportVisibleToUser(report, coReporterUserIds, user, ADMIN_PANEL_ROLES);
    if (ADMIN_PANEL_ROLES.includes(user.role)) {
      return this.findOneForModeration(reportId);
    }
    return this.findOneForCitizen(reportId, user);
  }

  async findOneForCitizen(
    reportId: string,
    user: AuthenticatedUser,
  ): Promise<CitizenReportDetailDto> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      include: {
        site: true,
        reporter: {
          select: { firstName: true, lastName: true },
        },
        coReporters: {
          include: {
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

    if (report.reporterId !== user.userId) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    const reporterName = report.reporter
      ? `${report.reporter.firstName} ${report.reporter.lastName}`.trim()
      : null;
    const coReporterNames = report.coReporters
      .map((cr) =>
        cr.user ? `${cr.user.firstName} ${cr.user.lastName}`.trim() : null,
      )
      .filter((n): n is string => !!n);

    const mediaUrls = await this.reportsUploadService.signUrls(report.mediaUrls);
    const pointTxns = await this.prisma.pointTransaction.findMany({
      where: { referenceType: 'Report', referenceId: reportId },
      select: { delta: true },
    });
    const pointsAwarded = pointTxns.reduce((sum, t) => sum + t.delta, 0);

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
    };
  }
}
