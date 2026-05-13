import { Injectable } from '@nestjs/common';
import { SiteShareChannel } from '../prisma-client';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ShareSiteDto } from './dto/share-site.dto';
import { SiteShareLinkRequestDto } from './dto/site-share-link-request.dto';
import { SiteEngagementService } from './site-engagement.service';
import { SitesEngagementSnapshotService } from './sites-engagement-snapshot.service';
import { SitesFeedService } from './sites-feed.service';
import { SitesReporterNotificationService } from './sites-reporter-notification.service';

/**
 * Coordinates site engagement mutations with feed cache invalidation and reporter notifications.
 * Extracted from the former {@link SitesService} façade.
 */
@Injectable()
export class SitesEngagementActionsService {
  constructor(
    private readonly siteEngagement: SiteEngagementService,
    private readonly sitesFeed: SitesFeedService,
    private readonly engagementSnapshot: SitesEngagementSnapshotService,
    private readonly reporterNotifications: SitesReporterNotificationService,
  ) {}

  async upvoteSite(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.upvote(siteId, user.userId);
    this.sitesFeed.invalidateFeedCache('site_upvoted', siteId);
    this.reporterNotifications.emitForSiteActivity(
      siteId,
      user.userId,
      'UPVOTE',
      'Your report received an upvote',
    );
    return this.engagementSnapshot.getSnapshot(siteId, user.userId);
  }

  async removeSiteUpvote(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.removeUpvote(siteId, user.userId);
    this.sitesFeed.invalidateFeedCache('site_upvote_removed', siteId);
    return this.engagementSnapshot.getSnapshot(siteId, user.userId);
  }

  async saveSite(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.save(siteId, user.userId);
    this.sitesFeed.invalidateFeedCache('site_saved', siteId);
    return this.engagementSnapshot.getSnapshot(siteId, user.userId);
  }

  async unsaveSite(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.unsave(siteId, user.userId);
    this.sitesFeed.invalidateFeedCache('site_unsaved', siteId);
    return this.engagementSnapshot.getSnapshot(siteId, user.userId);
  }

  async shareSite(siteId: string, dto: ShareSiteDto, user: AuthenticatedUser) {
    await this.siteEngagement.share(siteId, user.userId, dto.channel ?? SiteShareChannel.native);
    this.sitesFeed.invalidateFeedCache('site_shared', siteId);
    return this.engagementSnapshot.getSnapshot(siteId, user.userId);
  }

  async issueShareLink(siteId: string, dto: SiteShareLinkRequestDto, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const out = this.siteEngagement.issueShareLink(
      siteId,
      dto.channel ?? SiteShareChannel.native,
    );
    await this.siteEngagement.persistIssuedShareLink({
      siteId: out.siteId,
      cid: out.cid,
      channel: out.channel,
      expiresAt: out.expiresAt,
      userId: user.userId,
    });
    return out;
  }
}
