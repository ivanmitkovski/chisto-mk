import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AdminNotificationCategory,
  AdminNotificationTone,
  Prisma,
  Report,
  ReportCleanupEffort,
  ReportStatus,
  Role,
  SiteStatus,
} from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { distanceInMeters } from '../common/utils/distance';
import { CreateReportDto } from './dto/create-report.dto';
import { CreateReportWithLocationDto } from './dto/create-report-with-location.dto';
import { ReportSubmitResponseDto } from './dto/report-submit-response.dto';
import {
  AdminReportDetailDto,
  AdminReportListItemDto,
  AdminReportListResponseDto,
} from './dto/admin-report.dto';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  AdminDuplicateReportItemDto,
  MergeDuplicateReportsDto,
  MergeDuplicateReportsResponseDto,
} from './dto/admin-duplicate-report.dto';
import { ListMyReportsQueryDto } from './dto/list-my-reports-query.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { ReportCapacityDto } from './dto/report-capacity.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { CitizenReportDetailDto } from './dto/citizen-report-detail.dto';
import { UserReportListItemDto } from './dto/user-report.dto';
import { ReportsUploadService } from './reports-upload.service';
import { NotificationEventsService } from '../admin-events/notification-events.service';
import { ReportEventsService } from '../admin-events/report-events.service';
import { SiteEventsService } from '../admin-events/site-events.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import { parseReportCleanupEffort, reportCleanupEffortLabel } from './report-cleanup-effort';

const ALLOWED_REPORT_STATUS_TRANSITIONS: Record<ReportStatus, ReportStatus[]> = {
  NEW: ['IN_REVIEW', 'APPROVED', 'DELETED'],
  IN_REVIEW: ['APPROVED', 'DELETED'],
  APPROVED: ['DELETED'],
  DELETED: [],
};

const DUPLICATE_RADIUS_METERS = 30;
const SITE_NEARBY_RADIUS_METERS = 50;
const POINTS_FIRST_REPORT = 100;
const POINTS_CO_REPORT = 50;
const INITIAL_REPORT_CREDITS = 10;
const DEFAULT_EMERGENCY_WINDOW_DAYS = 7;

@Injectable()
export class ReportsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly reportEventsService: ReportEventsService,
    private readonly notificationEventsService: NotificationEventsService,
    private readonly siteEventsService: SiteEventsService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
  ) {}

  /** Fallback for reports created before reportNumber column (e.g. during migration). */
  private getReportNumberFallback(report: { id: string; createdAt: Date }): string {
    const shortId = report.id.slice(0, 4).toUpperCase();
    const yearSuffix = report.createdAt.getFullYear().toString().slice(-2);
    return `R-${yearSuffix}-${shortId}`;
  }

  private getReportNumber(report: { id: string; createdAt: Date; reportNumber?: string | null }): string {
    return report.reportNumber ?? this.getReportNumberFallback(report);
  }

  private buildLocationLabel(site: {
    latitude: number;
    longitude: number;
    description: string | null;
    address: string | null;
  }): string {
    const address = site.address?.trim();
    if (address) return address;
    const legacy = site.description?.trim();
    if (legacy) return legacy;

    const lat = site.latitude.toFixed(4);
    const lng = site.longitude.toFixed(4);
    return `${lat}, ${lng}`;
  }

  /** Report narrative for titles; falls back to legacy site.description when report text is empty. */
  private reportNarrativeTitle(
    reportDescription: string | null,
    legacySiteDescription: string | null,
  ): string {
    const narrative = reportDescription?.trim();
    if (narrative) return narrative;
    const legacy = legacySiteDescription?.trim();
    if (legacy) return legacy;
    return 'Reported site';
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

  private buildDuplicateReportItem(report: {
    id: string;
    createdAt: Date;
    status: ReportStatus;
    description: string | null;
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
      reportNumber: this.getReportNumber(report),
      title: this.reportNarrativeTitle(report.description, report.site.description),
      location: this.buildLocationLabel(report.site),
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

  /**
   * When the first report for a site is approved, transition site from REPORTED → VERIFIED.
   * Only updates when site is REPORTED; does not overwrite DISPUTED or other statuses.
   */
  private async transitionSiteToVerifiedIfFirstApproved(
    tx: Pick<PrismaService, 'site'>,
    siteId: string,
  ): Promise<void> {
    const site = await tx.site.findUnique({
      where: { id: siteId },
      select: { id: true, status: true },
    });
    if (!site || site.status !== SiteStatus.REPORTED) {
      return;
    }

    await tx.site.update({
      where: { id: siteId },
      data: { status: SiteStatus.VERIFIED },
    });
    this.siteEventsService.emitSiteUpdated(siteId);
  }

  private async findPrimaryReportId(reportId: string): Promise<string> {
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

  private emergencyRetryAfterSeconds(lastUsedAt: Date, windowDays: number, now: Date): number {
    const windowMs = windowDays * 24 * 60 * 60 * 1000;
    const unlockAtMs = lastUsedAt.getTime() + windowMs;
    return Math.max(1, Math.ceil((unlockAtMs - now.getTime()) / 1000));
  }

  private buildCapacityDto(
    user: {
      reportCreditsAvailable: number;
      reportEmergencyWindowDays: number;
      reportEmergencyUsedAt: Date | null;
    },
    now: Date,
  ): ReportCapacityDto {
    const windowDays = user.reportEmergencyWindowDays || DEFAULT_EMERGENCY_WINDOW_DAYS;
    const creditsAvailable = user.reportCreditsAvailable ?? INITIAL_REPORT_CREDITS;

    let emergencyAvailable = true;
    let retryAfterSeconds: number | null = null;
    if (user.reportEmergencyUsedAt) {
      const windowMs = windowDays * 24 * 60 * 60 * 1000;
      const unlockAtMs = user.reportEmergencyUsedAt.getTime() + windowMs;
      if (unlockAtMs > now.getTime()) {
        emergencyAvailable = false;
        retryAfterSeconds = this.emergencyRetryAfterSeconds(user.reportEmergencyUsedAt, windowDays, now);
      }
    }

    return {
      creditsAvailable,
      emergencyAvailable,
      emergencyWindowDays: windowDays,
      retryAfterSeconds,
      unlockHint: 'Join and verify attendance, or create an eco action to unlock 10 new reports.',
    };
  }

  private async spendReportCapacity(
    tx: Pick<PrismaService, 'user'>,
    userId: string,
    now: Date,
  ): Promise<void> {
    const spentFromCredits = await tx.user.updateMany({
      where: {
        id: userId,
        reportCreditsAvailable: { gt: 0 },
      },
      data: {
        reportCreditsAvailable: { decrement: 1 },
        reportCreditsSpentTotal: { increment: 1 },
      },
    });

    if (spentFromCredits.count > 0) {
      return;
    }

    const user = await tx.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        reportCreditsAvailable: true,
        reportEmergencyWindowDays: true,
        reportEmergencyUsedAt: true,
      },
    });

    if (!user) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: `User with id '${userId}' was not found`,
      });
    }

    const windowDays = user.reportEmergencyWindowDays || DEFAULT_EMERGENCY_WINDOW_DAYS;
    const emergencyAvailable =
      !user.reportEmergencyUsedAt ||
      user.reportEmergencyUsedAt.getTime() + windowDays * 24 * 60 * 60 * 1000 <= now.getTime();

    if (emergencyAvailable) {
      await tx.user.update({
        where: { id: userId },
        data: {
          reportEmergencyUsedAt: now,
          reportCreditsSpentTotal: { increment: 1 },
        },
      });
      return;
    }

    throw new HttpException({
      code: 'REPORTING_COOLDOWN',
      message:
        'You have used all report credits and emergency allowance. Join or create an eco action to unlock more reports.',
      details: {
        creditsAvailable: user.reportCreditsAvailable,
        emergencyAvailable: false,
        retryAfterSeconds: user.reportEmergencyUsedAt
          ? this.emergencyRetryAfterSeconds(user.reportEmergencyUsedAt, windowDays, now)
          : null,
        unlockHint: 'Join and verify attendance, or create an eco action to unlock 10 new reports.',
      },
    }, HttpStatus.TOO_MANY_REQUESTS);
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

  async createWithLocation(
    user: AuthenticatedUser,
    dto: CreateReportWithLocationDto,
  ): Promise<ReportSubmitResponseDto> {
    const { latitude, longitude, description, mediaUrls, category, severity, address } = dto;
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
      await this.spendReportCapacity(tx, user.userId, new Date());

      let siteId: string;
      let isNewSite: boolean;

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
      }

      const newReport = await tx.report.create({
        data: {
          siteId,
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
          },
        });
      }

      const reportNumber = this.getReportNumber(newReport);

      const notification = await tx.adminNotification.create({
        data: {
          title: isNewSite ? 'New pollution site reported' : 'Co-report added to existing site',
          message: `Report ${reportNumber} submitted${isNewSite ? ' at a new location' : ' near an existing site'}.`,
          timeLabel: 'Just now',
          tone: AdminNotificationTone.info,
          category: AdminNotificationCategory.reports,
          href: `/dashboard/reports?reportId=${newReport.id}`,
        },
      });

      return {
        reportId: newReport.id,
        reportNumber: this.getReportNumber(newReport),
        siteId,
        isNewSite,
        pointsAwarded: 0, // Points awarded when admin approves, not at submit
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
          reportNumber: this.getReportNumber(report),
          title: this.reportNarrativeTitle(report.description, report.site.description),
          location: this.buildLocationLabel(report.site),
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
    const current = await this.prisma.user.findUnique({
      where: { id: user.userId },
      select: {
        reportCreditsAvailable: true,
        reportEmergencyWindowDays: true,
        reportEmergencyUsedAt: true,
      },
    });

    if (!current) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: `User with id '${user.userId}' was not found`,
      });
    }

    return this.buildCapacityDto(current, new Date());
  }

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
        include: {
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
      reportNumber: this.getReportNumber(report),
      name: this.reportNarrativeTitle(report.description, report.site.description),
      location: report.site ? this.buildLocationLabel(report.site) : 'Unknown location',
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

  async mergeDuplicateReports(
    reportId: string,
    dto: MergeDuplicateReportsDto,
    moderator: AuthenticatedUser,
  ): Promise<MergeDuplicateReportsResponseDto> {
    const primaryReportId = await this.findPrimaryReportId(reportId);
    const now = new Date();

    const primaryReport = await this.prisma.report.findUnique({
      where: { id: primaryReportId },
      include: {
        coReporters: {
          select: {
            userId: true,
          },
        },
        potentialDuplicates: {
          include: {
            coReporters: {
              select: {
                userId: true,
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

    if (primaryReport.status === 'DELETED') {
      throw new BadRequestException({
        code: 'PRIMARY_REPORT_NOT_MERGEABLE',
        message: `Primary report '${primaryReportId}' is deleted and cannot be used as a merge target`,
      });
    }

    const childIdsInGroup = new Set(primaryReport.potentialDuplicates.map((child) => child.id));
    const selectedChildIds = [...new Set(dto.childReportIds)];
    const invalidChildIds = selectedChildIds.filter((childId) => !childIdsInGroup.has(childId));

    if (invalidChildIds.length > 0) {
      throw new BadRequestException({
        code: 'INVALID_DUPLICATE_SELECTION',
        message: 'One or more selected child reports do not belong to the duplicate group',
        details: {
          invalidChildIds,
        },
      });
    }

    const selectedChildren = primaryReport.potentialDuplicates.filter((child) => selectedChildIds.includes(child.id));
    if (selectedChildren.length === 0) {
      throw new BadRequestException({
        code: 'EMPTY_MERGE_SELECTION',
        message: 'At least one duplicate child report must be selected for merge',
      });
    }

    const mergedMediaUrls = [...new Set([...primaryReport.mediaUrls, ...selectedChildren.flatMap((child) => child.mediaUrls)])];

    const currentCoReporterIds = new Set(primaryReport.coReporters.map((coReporter) => coReporter.userId));
    const mergedReporterIds = new Set<string>();

    for (const child of selectedChildren) {
      if (child.reporterId && child.reporterId !== primaryReport.reporterId) {
        mergedReporterIds.add(child.reporterId);
      }

      for (const coReporter of child.coReporters) {
        if (coReporter.userId !== primaryReport.reporterId) {
          mergedReporterIds.add(coReporter.userId);
        }
      }
    }

    const newCoReporterIds = [...mergedReporterIds].filter((userId) => !currentCoReporterIds.has(userId));

    await this.prisma.$transaction(async (tx) => {
      if (newCoReporterIds.length > 0) {
        await tx.reportCoReporter.createMany({
          data: newCoReporterIds.map((userId) => ({
            reportId: primaryReport.id,
            userId,
          })),
          skipDuplicates: true,
        });
      }

      await tx.report.update({
        where: { id: primaryReport.id },
        data: {
          status: 'APPROVED',
          moderatedAt: now,
          moderatedById: moderator.userId,
          moderationReason: dto.reason ?? 'Merged duplicate',
          mediaUrls: mergedMediaUrls,
          potentialDuplicateOfId: null,
        },
      });

      const approvedCountForSite = await tx.report.count({
        where: {
          siteId: primaryReport.siteId,
          status: 'APPROVED',
        },
      });
      if (approvedCountForSite === 1) {
        await this.transitionSiteToVerifiedIfFirstApproved(tx, primaryReport.siteId);
      }

      await tx.report.updateMany({
        where: { id: { in: selectedChildIds } },
        data: {
          potentialDuplicateOfId: primaryReport.id,
          status: 'DELETED',
          moderatedAt: now,
          moderatedById: moderator.userId,
          moderationReason: dto.reason ?? 'Merged duplicate',
        },
      });
    });

    await this.audit.log({
      actorId: moderator.userId,
      action: 'REPORT_MERGE',
      resourceType: 'Report',
      resourceId: primaryReport.id,
      metadata: {
        mergedChildCount: selectedChildren.length,
        childReportIds: selectedChildIds,
      },
    });

    // Admin dashboard invalidation
    this.reportEventsService.emitReportStatusUpdated(primaryReport.id);
    for (const childId of selectedChildIds) {
      this.reportEventsService.emitReportStatusUpdated(childId);
    }

    // Owner-facing events (each affected report owner receives an update hint)
    if (primaryReport.reporterId) {
      this.reportsOwnerEventsService.emit(
        primaryReport.reporterId,
        primaryReport.id,
        'report_updated',
        { kind: 'merged', status: 'APPROVED' },
      );
    }
    for (const child of selectedChildren) {
      if (child.reporterId) {
        this.reportsOwnerEventsService.emit(
          child.reporterId,
          child.id,
          'report_updated',
          { kind: 'merged', status: 'DELETED' },
        );
      }
    }

    return {
      primaryReportId: primaryReport.id,
      mergedChildCount: selectedChildren.length,
      mergedMediaCount: mergedMediaUrls.length,
      mergedCoReporterCount: newCoReporterIds.length,
      primaryStatus: 'APPROVED',
    };
  }

  async updateStatus(
    reportId: string,
    dto: UpdateReportStatusDto,
    moderator: AuthenticatedUser,
  ): Promise<Report> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: { id: true, status: true, reporterId: true },
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

    const updated = await this.prisma.$transaction(async (tx) => {
      const updatedReport = await tx.report.update({
        where: { id: reportId },
        data: {
          status: dto.status,
          moderatedAt: now,
          moderationReason: dto.reason ?? null,
          moderatedById: moderator.userId,
        },
      });

      if (dto.status === 'APPROVED' && updatedReport.reporterId) {
        const existingAward = await tx.pointTransaction.findFirst({
          where: {
            referenceType: 'Report',
            referenceId: reportId,
          },
        });
        if (!existingAward) {
          const otherApprovedCount = await tx.report.count({
            where: {
              siteId: updatedReport.siteId,
              status: 'APPROVED',
              id: { not: reportId },
            },
          });
          const isFirstApproved = otherApprovedCount === 0;
          const points = isFirstApproved ? POINTS_FIRST_REPORT : POINTS_CO_REPORT;
          const user = await tx.user.findUnique({
            where: { id: updatedReport.reporterId },
            select: { pointsBalance: true, totalPointsEarned: true },
          });
          if (user) {
            const balanceAfter = user.pointsBalance + points;
            const totalEarnedAfter = user.totalPointsEarned + points;
            await tx.pointTransaction.create({
              data: {
                userId: updatedReport.reporterId,
                delta: points,
                balanceAfter,
                reasonCode: isFirstApproved ? 'FIRST_REPORT' : 'CO_REPORT',
                referenceType: 'Report',
                referenceId: reportId,
              },
            });
            await tx.user.update({
              where: { id: updatedReport.reporterId },
              data: {
                pointsBalance: balanceAfter,
                totalPointsEarned: totalEarnedAfter,
              },
            });
          }
        }
      }

      if (dto.status === 'APPROVED') {
        const otherApprovedCount = await tx.report.count({
          where: {
            siteId: updatedReport.siteId,
            status: 'APPROVED',
            id: { not: reportId },
          },
        });
        if (otherApprovedCount === 0) {
          await this.transitionSiteToVerifiedIfFirstApproved(tx, updatedReport.siteId);
        }
      }

      return updatedReport;
    });

    await this.audit.log({
      actorId: moderator.userId,
      action: 'REPORT_STATUS_UPDATED',
      resourceType: 'Report',
      resourceId: reportId,
      metadata: { from: report.status, to: dto.status },
    });

    this.reportEventsService.emitReportStatusUpdated(reportId);
    if (report.reporterId) {
      this.reportsOwnerEventsService.emit(
        report.reporterId,
        reportId,
        'report_updated',
        { kind: 'status_changed', status: dto.status },
      );
    }
    return updated;
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
        potentialDuplicates: {
          select: {
            id: true,
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

    const reportNumber = this.getReportNumber(report);
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
      report.potentialDuplicateOfId !== null || report.potentialDuplicates.length > 0 || coReporters.length > 0;

    const potentialDuplicateOfReportNumber = report.potentialDuplicateOf
      ? this.getReportNumber(report.potentialDuplicateOf)
      : null;

    return {
      id: report.id,
      reportNumber,
      status: report.status,
      priority: this.derivePriority(report.status),
      title: this.reportNarrativeTitle(report.description, report.site.description),
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
      cleanupEffortLabel: reportCleanupEffortLabel(report.cleanupEffort),
    };
  }

  async findOne(
    reportId: string,
    user: AuthenticatedUser,
  ): Promise<AdminReportDetailDto | CitizenReportDetailDto> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: { id: true, reporterId: true },
    });
    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }
    if (user.role === Role.ADMIN) {
      return this.findOneForModeration(reportId);
    }
    if (report.reporterId === user.userId) {
      return this.findOneForCitizen(reportId, user);
    }
    throw new NotFoundException({
      code: 'REPORT_NOT_FOUND',
      message: `Report with id '${reportId}' was not found`,
    });
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
      reportNumber: this.getReportNumber(report),
      status: report.status,
      description: report.description,
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
      location: this.buildLocationLabel(report.site),
      pointsAwarded,
      category: report.category ?? null,
      severity: report.severity ?? null,
      cleanupEffort: report.cleanupEffort ?? null,
    };
  }
}
