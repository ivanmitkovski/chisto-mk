import { Injectable, Logger } from '@nestjs/common';
import { SiteStatus } from '../prisma-client';
import { NotificationEventsService } from '../admin-events/notification-events.service';
import { ReportEventsService } from '../admin-events/report-events.service';
import { SiteEventsService } from '../admin-events/site-events.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';

export type ReportSubmitPostCreateEventsInput = {
  userId: string;
  reportId: string;
  siteId: string;
  isNewSite: boolean;
  notificationId: string;
  notificationTitle: string;
  siteUpdatedAt?: Date | null;
  latitude: number;
  longitude: number;
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
  ) {}

  emit(input: ReportSubmitPostCreateEventsInput): void {
    const {
      userId,
      reportId,
      siteId,
      isNewSite,
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
    this.logger.log(`report.submit ok reportId=${reportId} siteId=${siteId} isNewSite=${isNewSite}`);
  }
}
