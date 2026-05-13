import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SiteStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/audit.service';
import { reportMergePrimaryCopy, reportMergeChildCopy, reportCoReporterCreditCopy } from '../../notifications/notification-templates';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ReportsUploadService } from '../reports-upload.service';
import { ReportEventsService } from '../../admin-realtime/report-events.service';
import { SiteEventsService } from '../../admin-realtime/site-events.service';
import { ReportsOwnerEventsService } from '../reports-owner-events.service';
import { getReportNumber } from '../report-copy.helpers';

export type DuplicateMergeSiteStatusEvent = {
  id: string;
  status: SiteStatus;
  latitude: number;
  longitude: number;
  updatedAt: Date;
};

export type DuplicateMergePostTxInput = {
  moderator: AuthenticatedUser;
  primaryReport: {
    id: string;
    siteId: string;
    reporterId: string | null;
    reportNumber: string | null;
    createdAt: Date;
    mediaUrls: string[];
  };
  selectedChildIds: string[];
  selectedChildren: { id: string; reporterId: string | null }[];
  plannedNewCoReporterIds: string[];
  duplicateMediaUrls: string[];
  siteStatusEvent: DuplicateMergeSiteStatusEvent | null;
};

@Injectable()
export class DuplicateMergeSideEffectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly reportEventsService: ReportEventsService,
    private readonly siteEventsService: SiteEventsService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async runPostMergeEffects(input: DuplicateMergePostTxInput): Promise<number> {
    const {
      moderator,
      primaryReport,
      selectedChildIds,
      selectedChildren,
      plannedNewCoReporterIds,
      duplicateMediaUrls,
      siteStatusEvent,
    } = input;

    if (siteStatusEvent != null) {
      this.siteEventsService.emitSiteUpdated(siteStatusEvent.id, {
        kind: 'status_changed',
        status: siteStatusEvent.status,
        latitude: siteStatusEvent.latitude,
        longitude: siteStatusEvent.longitude,
        updatedAt: siteStatusEvent.updatedAt,
      });
    }

    const mergedMediaDeletedCount =
      await this.reportsUploadService.deleteReportMediaUrls(duplicateMediaUrls);

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

    this.reportEventsService.emitReportStatusUpdated(primaryReport.id);
    for (const childId of selectedChildIds) {
      this.reportEventsService.emitReportStatusUpdated(childId);
    }

    const primaryParties = await this.prisma.report.findUnique({
      where: { id: primaryReport.id },
      select: {
        reporterId: true,
        coReporters: { select: { userId: true } },
      },
    });
    if (primaryParties) {
      this.reportsOwnerEventsService.emitToReportInterestedParties(
        primaryReport.id,
        primaryParties.reporterId,
        primaryParties.coReporters.map((c) => c.userId),
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

    return mergedMediaDeletedCount;
  }

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
      const primaryCopy = reportMergePrimaryCopy('en', primaryReportNumberLabel);
      this.eventEmitter.emit('notification.send', {
        recipientUserIds: [primaryReporterId],
        title: primaryCopy.title,
        body: primaryCopy.body,
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
      const childCopy = reportMergeChildCopy('en', primaryReportNumberLabel);
      this.eventEmitter.emit('notification.send', {
        recipientUserIds: [userId],
        title: childCopy.title,
        body: childCopy.body,
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
      const coCopy = reportCoReporterCreditCopy('en', primaryReportNumberLabel);
      this.eventEmitter.emit('notification.send', {
        recipientUserIds: [userId],
        title: coCopy.title,
        body: coCopy.body,
        type: 'REPORT_STATUS',
        threadKey: `report:${primaryReportId}`,
        groupKey: `REPORT_STATUS:site:${siteId}`,
        data: { ...baseData, mergeRole: 'co_reporter_credited' },
      });
    }
  }
}
