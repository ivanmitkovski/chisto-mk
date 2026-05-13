import { Injectable } from '@nestjs/common';
import { SiteShareAttributionEventType, SiteShareAttributionSource, SiteShareChannel } from '../prisma-client';
import { SiteBookmarkService } from './site-bookmark.service';
import { SiteShareLinkService } from './site-share-link.service';
import { SiteUpvoteService } from './site-upvote.service';

@Injectable()
export class SiteEngagementService {
  constructor(
    private readonly upvotes: SiteUpvoteService,
    private readonly bookmarks: SiteBookmarkService,
    private readonly shareLinks: SiteShareLinkService,
  ) {}

  ensureSiteExists(siteId: string): Promise<void> {
    return this.upvotes.ensureSiteExists(siteId);
  }

  upvote(siteId: string, userId: string): Promise<void> {
    return this.upvotes.upvote(siteId, userId);
  }

  removeUpvote(siteId: string, userId: string): Promise<void> {
    return this.upvotes.removeUpvote(siteId, userId);
  }

  save(siteId: string, userId: string): Promise<void> {
    return this.bookmarks.save(siteId, userId);
  }

  unsave(siteId: string, userId: string): Promise<void> {
    return this.bookmarks.unsave(siteId, userId);
  }

  share(siteId: string, userId: string, channel: SiteShareChannel): Promise<void> {
    return this.shareLinks.share(siteId, userId, channel);
  }

  issueShareLink(siteId: string, channel: SiteShareChannel) {
    return this.shareLinks.issueShareLink(siteId, channel);
  }

  persistIssuedShareLink(input: {
    siteId: string;
    cid: string;
    channel: SiteShareChannel;
    expiresAt: string;
    userId: string;
  }): Promise<void> {
    return this.shareLinks.persistIssuedShareLink(input);
  }

  ingestAttributionEvent(input: {
    token: string;
    eventType: SiteShareAttributionEventType;
    source: SiteShareAttributionSource;
    ipAddress: string | null;
    userAgent: string | null;
    openedByUserId: string | undefined;
  }): Promise<{ counted: boolean; siteId: string; cid: string }> {
    return this.shareLinks.ingestAttributionEvent(input);
  }
}
