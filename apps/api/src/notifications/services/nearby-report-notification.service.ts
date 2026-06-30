import { Injectable, Logger } from '@nestjs/common';
import { NotificationType } from '../../prisma-client';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import { nearbyReportCopy } from '../../notifications/util/notification-templates';
import { NotificationDispatcherService } from './notification-dispatcher.service';
import { PrismaService } from '../../prisma/prisma.service';
import { NearbyUsersForReportService } from './nearby-users-for-report.service';

@Injectable()
export class NearbyReportNotificationService {
  private readonly logger = new Logger(NearbyReportNotificationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly nearbyUsers: NearbyUsersForReportService,
    private readonly dispatcher: NotificationDispatcherService,
  ) {}

  /**
   * Notifies users near a newly public site (report approved). Fire-and-forget.
   */
  emitForApprovedReport(params: {
    siteId: string;
    latitude: number;
    longitude: number;
    reporterId?: string | null;
    coReporterUserIds?: string[];
  }): void {
    void this._emit(params).catch((err: unknown) => {
      this.logger.warn({
        msg: 'nearby_report_notification_failed',
        siteId: params.siteId,
        error: String(err),
      });
    });
  }

  private async _emit(params: {
    siteId: string;
    latitude: number;
    longitude: number;
    reporterId?: string | null;
    coReporterUserIds?: string[];
  }): Promise<void> {
    const exclude = [
      ...(params.reporterId ? [params.reporterId] : []),
      ...(params.coReporterUserIds ?? []),
    ];
    const recipientIds = await this.nearbyUsers.findUserIdsNearSite({
      siteId: params.siteId,
      latitude: params.latitude,
      longitude: params.longitude,
      excludeUserIds: exclude,
    });
    if (recipientIds.length === 0) {
      return;
    }

    const localeBy = await notificationLocalesByUserId(this.prisma, recipientIds);
    for (const userId of recipientIds) {
      const locale = localeBy.get(userId)!;
      const { title, body } = nearbyReportCopy(locale);
      await this.dispatcher.dispatchToUser(userId, {
        title,
        body,
        type: NotificationType.NEARBY_REPORT,
        data: {
          siteId: params.siteId,
          targetTab: '0',
        },
        threadKey: `nearby_report:site:${params.siteId}:${userId}`,
        groupKey: `NEARBY_REPORT:site:${params.siteId}`,
      });
    }
  }
}
