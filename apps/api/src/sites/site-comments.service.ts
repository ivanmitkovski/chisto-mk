import { Injectable } from '@nestjs/common';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ListSiteCommentsQueryDto } from './dto/list-site-comments-query.dto';
import { CreateSiteCommentDto } from './dto/create-site-comment.dto';
import { UpdateSiteCommentDto } from './dto/update-site-comment.dto';
import { SiteCommentsListService } from './site-comments-list.service';
import { SiteCommentsMutationsService } from './site-comments-mutations.service';
import { SitesFeedService } from './sites-feed.service';
import { SitesReporterNotificationService } from './sites-reporter-notification.service';

export type { SiteCommentTreeNode } from './site-comments.types';

@Injectable()
export class SiteCommentsService {
  constructor(
    private readonly list: SiteCommentsListService,
    private readonly mutations: SiteCommentsMutationsService,
    private readonly sitesFeed: SitesFeedService,
    private readonly reporterNotifications: SitesReporterNotificationService,
  ) {}

  findSiteComments(
    siteId: string,
    query: ListSiteCommentsQueryDto,
    user?: AuthenticatedUser,
  ) {
    return this.list.findSiteComments(siteId, query, user);
  }

  async createSiteComment(siteId: string, dto: CreateSiteCommentDto, user: AuthenticatedUser) {
    const created = await this.mutations.createSiteComment(siteId, dto, user);
    this.sitesFeed.invalidateFeedCache('comment_created', siteId);
    this.reporterNotifications.emitForSiteActivity(
      siteId,
      user.userId,
      'COMMENT',
      'New comment on a site you follow',
    );
    return created;
  }

  async likeSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    const out = await this.mutations.likeSiteComment(siteId, commentId, user);
    this.sitesFeed.invalidateFeedCache('comment_liked', siteId);
    return out;
  }

  async unlikeSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    const out = await this.mutations.unlikeSiteComment(siteId, commentId, user);
    this.sitesFeed.invalidateFeedCache('comment_unliked', siteId);
    return out;
  }

  async updateSiteComment(
    siteId: string,
    commentId: string,
    dto: UpdateSiteCommentDto,
    user: AuthenticatedUser,
  ) {
    const updated = await this.mutations.updateSiteComment(siteId, commentId, dto, user);
    this.sitesFeed.invalidateFeedCache('comment_updated', siteId);
    return updated;
  }

  async deleteSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    const out = await this.mutations.deleteSiteComment(siteId, commentId, user);
    this.sitesFeed.invalidateFeedCache('comment_deleted', siteId);
    return out;
  }
}
