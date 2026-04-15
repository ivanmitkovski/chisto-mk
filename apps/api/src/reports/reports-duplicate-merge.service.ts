import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Prisma, ReportStatus, SiteStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  AdminDuplicateReportItemDto,
  MergeDuplicateReportsDto,
  MergeDuplicateReportsResponseDto,
} from './dto/admin-duplicate-report.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { ReportsUploadService } from './reports-upload.service';
import { ReportEventsService } from '../admin-events/report-events.service';
import { SiteEventsService } from '../admin-events/site-events.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import {
  displayReportTitle,
  getReportNumber,
  listLocationLabel,
} from './report-copy.helpers';
import { transitionSiteToVerifiedIfFirstApproved } from './report-site-verification.helper';

@Injectable()
export class ReportsDuplicateMergeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly reportEventsService: ReportEventsService,
    private readonly siteEventsService: SiteEventsService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

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

  private async buildMergeCompletedSnapshot(
    primaryReportId: string,
    metrics: {
      mergedChildCount: number;
      mergedMediaCount: number;
      mergedCoReporterCount: number;
    },
  ): Promise<MergeDuplicateReportsResponseDto> {
    const primaryAfter = await this.prisma.report.findUniqueOrThrow({
      where: { id: primaryReportId },
      select: {
        status: true,
        reporterId: true,
        coReporters: {
          select: {
            userId: true,
            reportedAt: true,
            user: {
              select: {
                firstName: true,
                lastName: true,
              },
            },
          },
          orderBy: { reportedAt: 'asc' },
        },
      },
    });

    const coReporters = primaryAfter.coReporters.map((row) => ({
      userId: row.userId,
      name: `${row.user.firstName} ${row.user.lastName}`.trim(),
      reportedAt: row.reportedAt.toISOString(),
    }));

    const reporterCount = (primaryAfter.reporterId ? 1 : 0) + primaryAfter.coReporters.length;

    return {
      primaryReportId,
      mergedChildCount: metrics.mergedChildCount,
      mergedMediaCount: metrics.mergedMediaCount,
      mergedCoReporterCount: metrics.mergedCoReporterCount,
      primaryStatus: primaryAfter.status,
      coReporters,
      reporterCount,
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
      select: {
        id: true,
        siteId: true,
        status: true,
        reporterId: true,
        reportNumber: true,
        createdAt: true,
        mediaUrls: true,
        coReporters: {
          select: {
            userId: true,
          },
        },
        potentialDuplicates: {
          select: {
            id: true,
            reporterId: true,
            createdAt: true,
            mediaUrls: true,
            coReporters: {
              select: {
                userId: true,
                createdAt: true,
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
      if (invalidChildIds.length !== selectedChildIds.length) {
        throw new BadRequestException({
          code: 'INVALID_DUPLICATE_SELECTION',
          message: 'One or more selected child reports do not belong to the duplicate group',
          details: {
            invalidChildIds,
          },
        });
      }
      // SECURITY: Idempotent merge retry — selection is no longer in the live duplicate group; only succeed if none of those IDs still exist as standalone reports (avoids accepting arbitrary unknown IDs).
      const orphanCount = await this.prisma.report.count({
        where: { id: { in: selectedChildIds } },
      });
      if (orphanCount > 0) {
        throw new BadRequestException({
          code: 'INVALID_DUPLICATE_SELECTION',
          message: 'One or more selected child reports do not belong to the duplicate group',
          details: {
            invalidChildIds,
          },
        });
      }
      return this.buildMergeCompletedSnapshot(primaryReport.id, {
        mergedChildCount: 0,
        mergedMediaCount: 0,
        mergedCoReporterCount: 0,
      });
    }

    const selectedChildren = primaryReport.potentialDuplicates.filter((child) =>
      selectedChildIds.includes(child.id),
    );
    if (selectedChildren.length === 0) {
      throw new BadRequestException({
        code: 'EMPTY_MERGE_SELECTION',
        message: 'At least one duplicate child report must be selected for merge',
      });
    }

    const duplicateMediaUrls = [...new Set(selectedChildren.flatMap((child) => child.mediaUrls))];

    const currentCoReporterIds = new Set(primaryReport.coReporters.map((coReporter) => coReporter.userId));
    /** Earliest known submission time per co-reporter user (from duplicate report or its co-report rows). */
    const coReporterReportedAt = new Map<string, Date>();
    const primaryReporterId = primaryReport.reporterId;

    const offerCoReporter = (userId: string | null | undefined, reportedAt: Date) => {
      if (!userId || userId === primaryReporterId) {
        return;
      }
      const prev = coReporterReportedAt.get(userId);
      if (!prev || reportedAt < prev) {
        coReporterReportedAt.set(userId, reportedAt);
      }
    };

    for (const child of selectedChildren) {
      offerCoReporter(child.reporterId, child.createdAt);
      for (const coReporter of child.coReporters) {
        offerCoReporter(coReporter.userId, coReporter.createdAt);
      }
    }

    const plannedNewCoReporterIds = [...coReporterReportedAt.keys()].filter(
      (userId) => !currentCoReporterIds.has(userId),
    );

    const mergeTxResult = await this.prisma.$transaction(async (tx) => {
      let siteStatusEvent: {
        id: string;
        status: SiteStatus;
        latitude: number;
        longitude: number;
        updatedAt: Date;
      } | null = null;

      // Any report that pointed at a child as its duplicate-of must point at the canonical primary before we delete children.
      await tx.report.updateMany({
        where: { potentialDuplicateOfId: { in: selectedChildIds } },
        data: { potentialDuplicateOfId: primaryReport.id },
      });

      for (const userId of plannedNewCoReporterIds) {
        const reportedAt = coReporterReportedAt.get(userId);
        if (!reportedAt) {
          continue;
        }
        await tx.reportCoReporter.upsert({
          where: {
            reportId_userId: {
              reportId: primaryReport.id,
              userId,
            },
          },
          update: {},
          create: {
            reportId: primaryReport.id,
            userId,
            reportedAt,
          },
        });
      }

      const primaryUpdate: Prisma.ReportUncheckedUpdateInput = {
        potentialDuplicateOfId: null,
        mergedDuplicateChildCount: { increment: selectedChildren.length },
      };
      if (primaryReport.status !== 'APPROVED') {
        primaryUpdate.status = 'APPROVED';
        primaryUpdate.moderatedAt = now;
        primaryUpdate.moderatedById = moderator.userId;
        primaryUpdate.moderationReason = dto.reason ?? 'Merged duplicate';
      }

      await tx.report.update({
        where: { id: primaryReport.id },
        data: primaryUpdate,
      });

      const approvedCountForSite = await tx.report.count({
        where: {
          siteId: primaryReport.siteId,
          status: 'APPROVED',
        },
      });
      if (approvedCountForSite === 1) {
        siteStatusEvent = await transitionSiteToVerifiedIfFirstApproved(tx, primaryReport.siteId);
      }

      await tx.report.deleteMany({
        where: { id: { in: selectedChildIds } },
      });

      return { siteStatusEvent };
    });
    const siteStatusEvent = mergeTxResult.siteStatusEvent;
    if (siteStatusEvent != null) {
      this.siteEventsService.emitSiteUpdated(siteStatusEvent.id, {
        kind: 'status_changed',
        status: siteStatusEvent.status,
        latitude: siteStatusEvent.latitude,
        longitude: siteStatusEvent.longitude,
        updatedAt: siteStatusEvent.updatedAt,
      });
    }

    const mergedMediaDeletedCount = await this.reportsUploadService.deleteReportMediaUrls(duplicateMediaUrls);

    await this.audit.log({
      actorId: moderator.userId,
      action: 'REPORT_MERGE',
      resourceType: 'Report',
      resourceId: primaryReport.id,
      metadata: {
        mergedChildCount: selectedChildren.length,
        childReportIds: selectedChildIds,
        duplicateMediaUrlsAttempted: duplicateMediaUrls.length,
        duplicateMediaObjectsDeleted: mergedMediaDeletedCount,
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

    const primaryReportNumberLabel = getReportNumber(primaryReport);
    this.emitDuplicateMergeNotifications({
      primaryReportId: primaryReport.id,
      siteId: primaryReport.siteId,
      primaryReporterId: primaryReport.reporterId,
      primaryReportNumberLabel,
      selectedChildren: selectedChildren.map((c) => ({ id: c.id, reporterId: c.reporterId })),
      plannedNewCoReporterIds,
    });

    return this.buildMergeCompletedSnapshot(primaryReport.id, {
      mergedChildCount: selectedChildren.length,
      mergedMediaCount: mergedMediaDeletedCount,
      mergedCoReporterCount: plannedNewCoReporterIds.length,
    });
  }

  /**
   * In-app + push notifications for duplicate merge outcomes.
   * Uses REPORT_STATUS so existing mute preferences apply; mergeRole distinguishes payloads.
   */
  private emitDuplicateMergeNotifications(params: {
    primaryReportId: string;
    siteId: string;
    primaryReporterId: string | null;
    primaryReportNumberLabel: string;
    selectedChildren: { id: string; reporterId: string | null }[];
    plannedNewCoReporterIds: string[];
  }): void {
    const {
      primaryReportId,
      siteId,
      primaryReporterId,
      primaryReportNumberLabel,
      selectedChildren,
      plannedNewCoReporterIds,
    } = params;

    const childReporterIds = new Set<string>();
    for (const child of selectedChildren) {
      if (child.reporterId) {
        childReporterIds.add(child.reporterId);
      }
    }

    const baseData = {
      reportId: primaryReportId,
      siteId,
      status: 'APPROVED' as const,
      reportNumber: primaryReportNumberLabel,
    };

    if (primaryReporterId != null && selectedChildren.length > 0) {
      this.eventEmitter.emit('notification.send', {
        recipientUserIds: [primaryReporterId],
        title: 'Duplicate reports merged',
        body: `Similar submissions were merged into your report ${primaryReportNumberLabel}.`,
        type: 'REPORT_STATUS',
        threadKey: `report:${primaryReportId}`,
        groupKey: `REPORT_STATUS:site:${siteId}`,
        data: { ...baseData, mergeRole: 'primary' },
      });
    }

    for (const userId of childReporterIds) {
      if (userId === primaryReporterId) {
        continue;
      }
      this.eventEmitter.emit('notification.send', {
        recipientUserIds: [userId],
        title: 'Your report was merged',
        body: `Your submission was merged into ${primaryReportNumberLabel}.`,
        type: 'REPORT_STATUS',
        threadKey: `report:${primaryReportId}`,
        groupKey: `REPORT_STATUS:site:${siteId}`,
        data: { ...baseData, mergeRole: 'merged_child' },
      });
    }

    for (const userId of plannedNewCoReporterIds) {
      if (userId === primaryReporterId || childReporterIds.has(userId)) {
        continue;
      }
      this.eventEmitter.emit('notification.send', {
        recipientUserIds: [userId],
        title: 'Co-reporter credit',
        body: `You are credited as a co-reporter on ${primaryReportNumberLabel}.`,
        type: 'REPORT_STATUS',
        threadKey: `report:${primaryReportId}`,
        groupKey: `REPORT_STATUS:site:${siteId}`,
        data: { ...baseData, mergeRole: 'co_reporter_credited' },
      });
    }
  }
}
