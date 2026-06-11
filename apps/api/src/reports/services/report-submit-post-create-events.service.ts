import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { AdminModerationCategory, SiteStatus } from '../../prisma-client';
import { AdminModerationNotifierService } from '../../admin-moderation-email/services/admin-moderation-notifier.service';
import { NotificationEventsService } from '../../admin-realtime/services/notification-events.service';
import { ReportEventsService } from '../../admin-realtime/services/report-events.service';
import { SiteEventsService } from '../../admin-realtime/services/site-events.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';

export type ReportSubmitPostCreateEventsInput = {
  userId: string;
  reportId: string;
  siteId: string;
  isNewSite: boolean;
  reportNumber: string;
  notificationId: string;
  notificationTitle: string;
  siteUpdatedAt?: Date | null;
  latitude: number;
  longitude: number;
  reportTitle: string;
  category?: string | null;
  severity?: number | null;
  address?: string | null;
  descriptionPreview?: string | null;
  reporterEmail: string;
  submittedAt: string;
};

/**
 * Webhook-style fan-out after a report row (and optional site) is committed.
 * Keeps {@link ReportSubmitService} focused on validation + Prisma transaction.
 */
@Injectable()
export class ReportSubmitPostCreateEventsService {
  private readonly logger = new Logger(ReportSubmitPostCreateEventsService.name);

  constructor(
    private readonly reportEventsService: ReportEventsService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
    private readonly notificationEventsService: NotificationEventsService,
    private readonly siteEventsService: SiteEventsService,
    private readonly moderationEmailNotifier: AdminModerationNotifierService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  emit(input: ReportSubmitPostCreateEventsInput): void {
    const {
      userId,
      reportId,
      siteId,
      isNewSite,
      reportNumber,
      notificationId,
      notificationTitle,
      siteUpdatedAt,
      latitude,
      longitude,
    } = input;

    this.reportEventsService.emitReportCreated(reportId);
    this.reportsOwnerEventsService.emit(userId, reportId, 'report_created', {
      kind: 'created',
    });
    this.notificationEventsService.emitNotificationCreated(notificationId, notificationTitle);
    if (isNewSite) {
      this.siteEventsService.emitSiteCreated(siteId, {
        status: SiteStatus.REPORTED,
        latitude,
        longitude,
        ...(siteUpdatedAt != null ? { updatedAt: siteUpdatedAt } : {}),
      });
    } else {
      this.siteEventsService.emitSiteUpdated(siteId, { kind: 'updated' });
    }
    this.moderationEmailNotifier.notify({
      category: AdminModerationCategory.NEW_REPORT,
      resourceId: reportId,
      deepLinkPath: `/dashboard/reports?reportId=${reportId}`,
      emailContext: {
        reportNumber,
        isNewSite,
        reportTitle: input.reportTitle,
        category: input.category ?? null,
        severity: input.severity ?? null,
        address: input.address ?? null,
        latitude: input.latitude,
        longitude: input.longitude,
        descriptionPreview: input.descriptionPreview ?? null,
        reporterEmail: input.reporterEmail,
        submittedAt: input.submittedAt,
      },
    });

    this.logger.log(`report.submit ok reportId=${reportId} siteId=${siteId} isNewSite=${isNewSite}`);

    this.eventEmitter.emit('report.submitted', {
      userId,
      metadata: { reportId, siteId, reportNumber },
    });
  }
}
