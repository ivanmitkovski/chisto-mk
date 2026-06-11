import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SiteStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import {
  formatSiteStatusLabel,
  siteCommentCopy,
  siteStatusUpdateCopy,
  siteUpvoteCopy,
} from '../../notifications/util/notification-templates';

/** Placeholder actor id for automated site status transitions (non-user). */
export const SITE_NOTIFICATION_SYSTEM_ACTOR_ID = '__system__';

const MEANINGFUL_SITE_STATUS_UPDATES: SiteStatus[] = [
  SiteStatus.VERIFIED,
  SiteStatus.CLEANUP_SCHEDULED,
  SiteStatus.IN_PROGRESS,
  SiteStatus.CLEANED,
];

@Injectable()
export class SitesReporterNotificationService {
  private readonly logger = new Logger(SitesReporterNotificationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  emitSiteStatusUpdate(
    siteId: string,
    actorUserId: string,
    toStatus: SiteStatus,
    options?: { skipRecipientIds?: string[] },
  ): void {
    if (!MEANINGFUL_SITE_STATUS_UPDATES.includes(toStatus)) {
      return;
    }
    void this._fanoutSiteUpdate(siteId, actorUserId, toStatus, options?.skipRecipientIds ?? []).catch(
      (err: unknown) => {
        this.logger.warn({
          msg: 'site_status_update_notification_failed',
          siteId,
          toStatus,
          error: String(err),
        });
      },
    );
  }

  emitForSiteActivity(
    siteId: string,
    actorUserId: string,
    type: 'UPVOTE' | 'COMMENT' | 'SITE_UPDATE',
    body: string,
    messagePreview?: string,
    commentId?: string,
  ): void {
    void this.prisma.site
      .findUnique({
        where: { id: siteId },
        select: {
          id: true,
          reports: {
            select: { reporterId: true },
            where: { reporterId: { not: null } },
            take: 50,
          },
        },
      })
      .then(async (site) => {
        if (!site) return;
        const recipientIds = [
          ...new Set(
            site.reports
              .map((r) => r.reporterId)
              .filter((id): id is string => id != null && id !== actorUserId),
          ),
        ];
        if (recipientIds.length === 0) return;
        const localeBy = await notificationLocalesByUserId(this.prisma, recipientIds);
        for (const recipientId of recipientIds) {
          const locale = localeBy.get(recipientId)!;
          const copy =
            type === 'UPVOTE'
              ? siteUpvoteCopy(locale)
              : type === 'COMMENT'
                ? siteCommentCopy(locale, messagePreview)
                : siteStatusUpdateCopy(locale, body);
          this.eventEmitter.emit('notification.send', {
            recipientUserIds: [recipientId],
            title: copy.title,
            body: copy.body,
            type,
            threadKey: `site:${siteId}`,
            groupKey: `${type}:site:${siteId}`,
            data: {
              siteId,
              actorUserId,
              targetTab: '0',
              ...(type === 'UPVOTE' ? { targetAction: 'show_upvoters' } : {}),
              ...(type === 'COMMENT'
                ? {
                    targetAction: 'show_comments',
                    ...(messagePreview ? { messagePreview } : {}),
                    ...(commentId ? { commentId } : {}),
                  }
                : {}),
            },
          });
        }
      })
      .catch((err: unknown) => {
        this.logger.warn({
          msg: 'reporter_notification_fanout_failed',
          siteId,
          type,
          error: String(err),
        });
      });
  }

  private async _fanoutSiteUpdate(
    siteId: string,
    actorUserId: string,
    toStatus: SiteStatus,
    skipRecipientIds: string[],
  ): Promise<void> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      select: {
        id: true,
        reports: {
          select: { reporterId: true },
          where: { reporterId: { not: null } },
          take: 50,
        },
      },
    });
    if (!site) return;

    const skip = new Set(skipRecipientIds);
    const recipientIds = [
      ...new Set(
        site.reports
          .map((r) => r.reporterId)
          .filter(
            (id): id is string =>
              id != null && id !== actorUserId && !skip.has(id),
          ),
      ),
    ];
    if (recipientIds.length === 0) return;

    const localeBy = await notificationLocalesByUserId(this.prisma, recipientIds);
    for (const recipientId of recipientIds) {
      const locale = localeBy.get(recipientId)!;
      const statusLabel = formatSiteStatusLabel(toStatus, locale);
      const copy = siteStatusUpdateCopy(locale, statusLabel);
      this.eventEmitter.emit('notification.send', {
        recipientUserIds: [recipientId],
        title: copy.title,
        body: copy.body,
        type: 'SITE_UPDATE',
        threadKey: `site:${siteId}`,
        groupKey: `SITE_UPDATE:site:${siteId}`,
        data: {
          siteId,
          actorUserId,
          targetTab: '0',
          status: toStatus,
        },
      });
    }
  }
}
