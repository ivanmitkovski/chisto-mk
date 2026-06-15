import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SiteStatus } from '../../../prisma-client';
import { PrismaService } from '../../../prisma/prisma.service';
import { notificationLocalesByUserId } from '../../../common/i18n/notification-locale.resolver';
import {
  formatSiteStatusLabel,
  siteResolutionApprovedCopy,
  siteResolutionRejectedCopy,
  siteResolvedCopy,
  siteStatusUpdateCopy,
} from '../../../notifications/util/notification-templates';

@Injectable()
export class SiteResolutionNotificationService {
  private readonly logger = new Logger(SiteResolutionNotificationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async notifySubmitter(params: {
    submitterId: string;
    siteId: string;
    resolutionId: string;
    status: 'APPROVED' | 'REJECTED';
  }): Promise<void> {
    try {
      const localeBy = await notificationLocalesByUserId(this.prisma, [params.submitterId]);
      const locale = localeBy.get(params.submitterId)!;
      const copy =
        params.status === 'APPROVED'
          ? siteResolutionApprovedCopy(locale)
          : siteResolutionRejectedCopy(locale);

      this.eventEmitter.emit('notification.send', {
        recipientUserIds: [params.submitterId],
        title: copy.title,
        body: copy.body,
        type: 'SITE_UPDATE',
        threadKey: `site:${params.siteId}`,
        groupKey: `SITE_RESOLUTION:${params.resolutionId}`,
        data: {
          kind: 'site_resolution',
          siteId: params.siteId,
          resolutionId: params.resolutionId,
          status: params.status,
        },
      });
    } catch (err) {
      this.logger.warn({
        msg: 'site_resolution_submitter_notification_failed',
        resolutionId: params.resolutionId,
        error: String(err),
      });
    }
  }

  async notifySiteResolved(params: {
    siteId: string;
    actorUserId: string;
    skipRecipientIds?: string[];
  }): Promise<void> {
    try {
      const skip = new Set(params.skipRecipientIds ?? []);
      skip.add(params.actorUserId);

      const [site, savers] = await Promise.all([
        this.prisma.site.findUnique({
          where: { id: params.siteId },
          select: {
            reports: {
              where: { reporterId: { not: null } },
              select: { reporterId: true },
            },
          },
        }),
        this.prisma.siteSave.findMany({
          where: { siteId: params.siteId },
          select: { userId: true },
        }),
      ]);

      if (!site) return;

      const coReporters = await this.prisma.reportCoReporter.findMany({
        where: { report: { siteId: params.siteId } },
        select: { userId: true },
      });

      const recipientIds = [
        ...new Set([
          ...site.reports.map((r) => r.reporterId).filter((id): id is string => id != null),
          ...coReporters.map((c) => c.userId).filter((id): id is string => id != null),
          ...savers.map((s) => s.userId),
        ]),
      ].filter((id) => !skip.has(id));

      if (recipientIds.length === 0) return;

      const localeBy = await notificationLocalesByUserId(this.prisma, recipientIds);

      for (const recipientId of recipientIds) {
        const locale = localeBy.get(recipientId)!;
        const copy = siteResolvedCopy(locale);
        const statusCopy = siteStatusUpdateCopy(
          locale,
          formatSiteStatusLabel(SiteStatus.CLEANED, locale),
        );
        this.eventEmitter.emit('notification.send', {
          recipientUserIds: [recipientId],
          title: copy.title,
          body: statusCopy.body,
          type: 'SITE_UPDATE',
          threadKey: `site:${params.siteId}`,
          groupKey: `SITE_UPDATE:site:${params.siteId}`,
          data: {
            siteId: params.siteId,
            status: SiteStatus.CLEANED,
            kind: 'site_resolved',
            targetTab: '0',
          },
        });
      }
    } catch (err) {
      this.logger.warn({
        msg: 'site_resolved_notification_failed',
        siteId: params.siteId,
        error: String(err),
      });
    }
  }
}
