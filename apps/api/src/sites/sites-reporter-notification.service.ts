import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../prisma/prisma.service';
import { siteUpvoteCopy, siteCommentCopy, siteUpdateCopy } from '../notifications/notification-templates';

@Injectable()
export class SitesReporterNotificationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  emitForSiteActivity(
    siteId: string,
    actorUserId: string,
    type: 'UPVOTE' | 'COMMENT' | 'SITE_UPDATE',
    body: string,
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
      .then((site) => {
        if (!site) return;
        const recipientIds = [
          ...new Set(
            site.reports
              .map((r) => r.reporterId)
              .filter((id): id is string => id != null && id !== actorUserId),
          ),
        ];
        if (recipientIds.length === 0) return;
        const copy =
          type === 'UPVOTE'
            ? siteUpvoteCopy('en')
            : type === 'COMMENT'
              ? siteCommentCopy('en')
              : siteUpdateCopy('en', body);
        this.eventEmitter.emit('notification.send', {
          recipientUserIds: recipientIds,
          title: copy.title,
          body: copy.body,
          type,
          threadKey: `site:${siteId}`,
          groupKey: `${type}:site:${siteId}`,
          data: { siteId, targetTab: '0' },
        });
      })
      .catch(() => {
        // Deliberate: notification fan-out must not fail the primary mutation.
      });
  }
}
