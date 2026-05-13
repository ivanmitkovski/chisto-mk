import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { ReportSideEffectKind, ReportSideEffectStatus, ReportStatus, SiteStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/audit.service';
import { reportStatusCopy } from '../../notifications/notification-templates';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ReportEventsService } from '../../admin-realtime/report-events.service';
import { SiteEventsService } from '../../admin-realtime/site-events.service';
import { ReportsOwnerEventsService } from '../reports-owner-events.service';
import {
  DuplicateMergePostTxInput,
  DuplicateMergeSideEffectsService,
  DuplicateMergeSiteStatusEvent,
} from '../duplicates/duplicate-merge-side-effects.service';

/** JSON shape stored for [ReportSideEffectKind.MERGE_DUPLICATE_POST]. */
export type MergeDuplicateSideEffectPayload = {
  moderator: AuthenticatedUser;
  primaryReport: {
    id: string;
    siteId: string;
    reporterId: string | null;
    reportNumber: string | null;
    createdAt: string;
    mediaUrls: string[];
  };
  selectedChildIds: string[];
  selectedChildren: { id: string; reporterId: string | null }[];
  plannedNewCoReporterIds: string[];
  duplicateMediaUrls: string[];
  siteStatusEvent: {
    id: string;
    status: SiteStatus;
    latitude: number;
    longitude: number;
    updatedAt: string;
  } | null;
};

/** JSON shape stored for [ReportSideEffectKind.MODERATION_STATUS_POST]. */
export type ModerationStatusSideEffectPayload = {
  moderatorUserId: string;
  reportId: string;
  fromStatus: ReportStatus;
  toStatus: ReportStatus;
  reason: string | null;
  siteId: string;
  reporterId: string | null;
  coReporterUserIds: string[];
  siteStatusEvent: {
    id: string;
    status: SiteStatus;
    latitude: number;
    longitude: number;
    updatedAt: string;
  } | null;
};

@Injectable()
export class ReportSideEffectProcessorService {
  private readonly logger = new Logger(ReportSideEffectProcessorService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly duplicateMergeSideEffects: DuplicateMergeSideEffectsService,
    private readonly audit: AuditService,
    private readonly reportEventsService: ReportEventsService,
    private readonly siteEventsService: SiteEventsService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async processMergeDuplicatePost(effectId: string): Promise<number> {
    const row = await this.prisma.reportSideEffect.findUnique({
      where: { id: effectId },
    });
    if (!row || row.kind !== ReportSideEffectKind.MERGE_DUPLICATE_POST) {
      this.logger.warn(`processMergeDuplicatePost: skip missing or wrong kind id=${effectId}`);
      return 0;
    }
    if (row.status === ReportSideEffectStatus.COMPLETED) {
      return 0;
    }

    await this.prisma.reportSideEffect.update({
      where: { id: effectId },
      data: {
        status: ReportSideEffectStatus.PROCESSING,
        attempts: { increment: 1 },
      },
    });

    const raw = row.payload as unknown as MergeDuplicateSideEffectPayload;
    try {
      const siteStatusEvent: DuplicateMergeSiteStatusEvent | null =
        raw.siteStatusEvent == null
          ? null
          : {
              id: raw.siteStatusEvent.id,
              status: raw.siteStatusEvent.status,
              latitude: raw.siteStatusEvent.latitude,
              longitude: raw.siteStatusEvent.longitude,
              updatedAt: new Date(raw.siteStatusEvent.updatedAt),
            };

      const input: DuplicateMergePostTxInput = {
        moderator: raw.moderator,
        primaryReport: {
          ...raw.primaryReport,
          createdAt: new Date(raw.primaryReport.createdAt),
        },
        selectedChildIds: raw.selectedChildIds,
        selectedChildren: raw.selectedChildren,
        plannedNewCoReporterIds: raw.plannedNewCoReporterIds,
        duplicateMediaUrls: raw.duplicateMediaUrls,
        siteStatusEvent,
      };

      const mergedMediaDeletedCount =
        await this.duplicateMergeSideEffects.runPostMergeEffects(input);

      await this.prisma.reportSideEffect.update({
        where: { id: effectId },
        data: {
          status: ReportSideEffectStatus.COMPLETED,
          processedAt: new Date(),
          lastError: null,
        },
      });

      return mergedMediaDeletedCount;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(`MERGE_DUPLICATE_POST side effect failed id=${effectId}`, err);
      await this.prisma.reportSideEffect.update({
        where: { id: effectId },
        data: {
          status: ReportSideEffectStatus.FAILED,
          lastError: message.slice(0, 4000),
        },
      });
      return 0;
    }
  }

  async processModerationStatusPost(effectId: string): Promise<void> {
    const row = await this.prisma.reportSideEffect.findUnique({
      where: { id: effectId },
    });
    if (!row || row.kind !== ReportSideEffectKind.MODERATION_STATUS_POST) {
      this.logger.warn(`processModerationStatusPost: skip missing or wrong kind id=${effectId}`);
      return;
    }
    if (row.status === ReportSideEffectStatus.COMPLETED) {
      return;
    }

    await this.prisma.reportSideEffect.update({
      where: { id: effectId },
      data: {
        status: ReportSideEffectStatus.PROCESSING,
        attempts: { increment: 1 },
      },
    });

    const raw = row.payload as unknown as ModerationStatusSideEffectPayload;
    try {
      if (raw.siteStatusEvent != null) {
        this.siteEventsService.emitSiteUpdated(raw.siteStatusEvent.id, {
          kind: 'status_changed',
          status: raw.siteStatusEvent.status,
          latitude: raw.siteStatusEvent.latitude,
          longitude: raw.siteStatusEvent.longitude,
          updatedAt: new Date(raw.siteStatusEvent.updatedAt),
        });
      }

      await this.audit.log({
        actorId: raw.moderatorUserId,
        action: 'REPORT_STATUS_UPDATED',
        resourceType: 'Report',
        resourceId: raw.reportId,
        metadata: {
          from: raw.fromStatus,
          to: raw.toStatus,
          ...(raw.reason != null && raw.reason.trim() !== '' ? { reason: raw.reason.trim() } : {}),
        },
      });

      this.reportEventsService.emitReportStatusUpdated(raw.reportId);
      this.reportsOwnerEventsService.emitToReportInterestedParties(
        raw.reportId,
        raw.reporterId,
        raw.coReporterUserIds,
        'report_updated',
        { kind: 'status_changed', status: raw.toStatus },
      );

      const recipientUserIds = [
        ...(raw.reporterId ? [raw.reporterId] : []),
        ...raw.coReporterUserIds,
      ];
      const uniqueRecipients = [...new Set(recipientUserIds)];
      if (uniqueRecipients.length > 0) {
        const statusLabel = raw.toStatus.toLowerCase().replace(/_/g, ' ');
        const copy = reportStatusCopy('en', statusLabel);
        this.eventEmitter.emit('notification.send', {
          recipientUserIds: uniqueRecipients,
          title: copy.title,
          body: copy.body,
          type: 'REPORT_STATUS',
          threadKey: `report:${raw.reportId}`,
          groupKey: `REPORT_STATUS:site:${raw.siteId}`,
          data: { reportId: raw.reportId, siteId: raw.siteId, status: raw.toStatus },
        });
      }

      await this.prisma.reportSideEffect.update({
        where: { id: effectId },
        data: {
          status: ReportSideEffectStatus.COMPLETED,
          processedAt: new Date(),
          lastError: null,
        },
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(`MODERATION_STATUS_POST side effect failed id=${effectId}`, err);
      await this.prisma.reportSideEffect.update({
        where: { id: effectId },
        data: {
          status: ReportSideEffectStatus.FAILED,
          lastError: message.slice(0, 4000),
        },
      });
    }
  }
}
