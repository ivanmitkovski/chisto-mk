import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../../prisma/prisma.service';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import { siteUpvoteCopy, siteCommentCopy, siteUpdateCopy } from '../../notifications/util/notification-templates';

@Injectable()
export class SitesReporterNotificationService {
  private readonly logger = new Logger(SitesReporterNotificationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

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
          const locale = localeBy.get(recipientId) === 'en' ? 'en' : 'mk';
          const copy =
            type === 'UPVOTE'
              ? siteUpvoteCopy(locale)
              : type === 'COMMENT'
                ? siteCommentCopy(locale, messagePreview)
                : siteUpdateCopy(locale, body);
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
}
