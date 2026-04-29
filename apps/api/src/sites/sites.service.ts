import { Injectable, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SiteShareChannel } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { CreateSiteDto } from './dto/create-site.dto';
import { ListSiteCommentsQueryDto } from './dto/list-site-comments-query.dto';
import { ListSiteMediaQueryDto } from './dto/list-site-media-query.dto';
import { ListSitesMapQueryDto } from './dto/list-sites-map-query.dto';
import { ListSiteUpvotesQueryDto } from './dto/list-site-upvotes-query.dto';
import { ListSitesQueryDto } from './dto/list-sites-query.dto';
import { CreateSiteCommentDto } from './dto/create-site-comment.dto';
import { UpdateSiteCommentDto } from './dto/update-site-comment.dto';
import { ShareSiteDto } from './dto/share-site.dto';
import { SiteShareAttributionEventDto } from './dto/site-share-attribution-event.dto';
import { SiteShareLinkRequestDto } from './dto/site-share-link-request.dto';
import { SubmitFeedFeedbackDto } from './dto/submit-feed-feedback.dto';
import { TrackFeedEventDto } from './dto/track-feed-event.dto';
import { UpdateSiteStatusDto } from './dto/update-site-status.dto';
import { SiteCommentsService } from './site-comments.service';
import type { SiteCommentTreeNode } from './site-comments.service';
import { SiteEngagementService } from './site-engagement.service';
import { SitesAdminService } from './sites-admin.service';
import { SitesDetailService } from './sites-detail.service';
import { SitesFeedService } from './sites-feed.service';
import { SitesMapQueryService } from './sites-map-query.service';
import { SitesMediaService } from './sites-media.service';
import { SiteUpvotesRepository } from './repositories/site-upvotes.repository';

@Injectable()
export class SitesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly siteEngagement: SiteEngagementService,
    private readonly siteComments: SiteCommentsService,
    private readonly eventEmitter: EventEmitter2,
    private readonly sitesMapQuery: SitesMapQueryService,
    private readonly sitesFeed: SitesFeedService,
    private readonly sitesDetail: SitesDetailService,
    private readonly sitesMedia: SitesMediaService,
    private readonly sitesAdmin: SitesAdminService,
    private readonly siteUpvotesRepository: SiteUpvotesRepository,
  ) {}

  async findAllForMap(query: ListSitesMapQueryDto) {
    return this.sitesMapQuery.findAllForMap(query);
  }

  create(dto: CreateSiteDto) {
    return this.sitesAdmin.create(dto);
  }

  findAll(query: ListSitesQueryDto, user?: AuthenticatedUser) {
    return this.sitesFeed.findAll(query, user);
  }

  getFeedVariantForUser(userId: string | undefined) {
    return this.sitesFeed.getFeedVariantForUser(userId);
  }

  findOne(siteId: string, user?: AuthenticatedUser) {
    return this.sitesDetail.findOne(siteId, user);
  }

  findSiteMedia(siteId: string, query: ListSiteMediaQueryDto) {
    return this.sitesMedia.findSiteMedia(siteId, query);
  }

  async findSiteUpvotes(siteId: string, query: ListSiteUpvotesQueryDto): Promise<{
    data: Array<{
      userId: string;
      displayName: string;
      avatarUrl: string | null;
      upvotedAt: string;
    }>;
    meta: { page: number; limit: number; total: number; hasMore: boolean };
  }> {
    await this.siteEngagement.ensureSiteExists(siteId);
    const skip = (query.page - 1) * query.limit;
    const [total, votes] = await Promise.all([
      this.siteUpvotesRepository.countBySiteId(siteId),
      this.siteUpvotesRepository.findPageBySiteId({
        siteId,
        skip,
        take: query.limit,
      }),
    ]);
    const data = await Promise.all(
      votes.map(async (vote) => {
        const displayName =
          `${vote.user.firstName ?? ''} ${vote.user.lastName ?? ''}`.trim() || 'Anonymous';
        const avatarUrl = await this.reportsUploadService.resolveUserAvatarUrl(
          vote.user.avatarObjectKey,
        );
        return {
          userId: vote.user.id,
          displayName,
          avatarUrl,
          upvotedAt: vote.createdAt.toISOString(),
        };
      }),
    );
    const loadedThrough = skip + data.length;
    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        hasMore: loadedThrough < total,
      },
    };
  }

  async findSiteComments(
    siteId: string,
    query: ListSiteCommentsQueryDto,
    user?: AuthenticatedUser,
  ): Promise<{ data: SiteCommentTreeNode[]; meta: { page: number; limit: number; total: number } }> {
    return this.siteComments.findSiteComments(siteId, query, user);
  }

  async createSiteComment(siteId: string, dto: CreateSiteCommentDto, user: AuthenticatedUser) {
    const created = await this.siteComments.createSiteComment(siteId, dto, user);
    this.sitesFeed.invalidateFeedCache('comment_created', siteId);
    this.emitSiteNotification(siteId, user.userId, 'COMMENT', 'New comment on a site you follow');
    return created;
  }

  async likeSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    const out = await this.siteComments.likeSiteComment(siteId, commentId, user);
    this.sitesFeed.invalidateFeedCache('comment_liked', siteId);
    return out;
  }

  async unlikeSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    const out = await this.siteComments.unlikeSiteComment(siteId, commentId, user);
    this.sitesFeed.invalidateFeedCache('comment_unliked', siteId);
    return out;
  }

  async updateSiteComment(
    siteId: string,
    commentId: string,
    dto: UpdateSiteCommentDto,
    user: AuthenticatedUser,
  ) {
    const updated = await this.siteComments.updateSiteComment(siteId, commentId, dto, user);
    this.sitesFeed.invalidateFeedCache('comment_updated', siteId);
    return updated;
  }

  async deleteSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    const out = await this.siteComments.deleteSiteComment(siteId, commentId, user);
    this.sitesFeed.invalidateFeedCache('comment_deleted', siteId);
    return out;
  }

  async upvoteSite(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.upvote(siteId, user.userId);
    this.sitesFeed.invalidateFeedCache('site_upvoted', siteId);
    this.emitSiteNotification(siteId, user.userId, 'UPVOTE', 'Your report received an upvote');
    return this.getEngagementSnapshot(siteId, user.userId);
  }

  async removeSiteUpvote(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.removeUpvote(siteId, user.userId);
    this.sitesFeed.invalidateFeedCache('site_upvote_removed', siteId);
    return this.getEngagementSnapshot(siteId, user.userId);
  }

  async saveSite(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.save(siteId, user.userId);
    this.sitesFeed.invalidateFeedCache('site_saved', siteId);
    return this.getEngagementSnapshot(siteId, user.userId);
  }

  async unsaveSite(siteId: string, user: AuthenticatedUser) {
    await this.siteEngagement.unsave(siteId, user.userId);
    this.sitesFeed.invalidateFeedCache('site_unsaved', siteId);
    return this.getEngagementSnapshot(siteId, user.userId);
  }

  async shareSite(siteId: string, dto: ShareSiteDto, user: AuthenticatedUser) {
    await this.siteEngagement.share(siteId, user.userId, dto.channel ?? SiteShareChannel.native);
    this.sitesFeed.invalidateFeedCache('site_shared', siteId);
    return this.getEngagementSnapshot(siteId, user.userId);
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

  async ingestShareAttributionEvent(input: {
    dto: SiteShareAttributionEventDto;
    ipAddress: string | null;
    userAgent: string | null;
    openedByUserId: string | undefined;
  }) {
    return this.siteEngagement.ingestAttributionEvent({
      token: input.dto.token,
      eventType: input.dto.eventType,
      source: input.dto.source,
      ipAddress: input.ipAddress,
      userAgent: input.userAgent,
      openedByUserId: input.openedByUserId,
    });
  }

  trackFeedEvent(dto: TrackFeedEventDto, user: AuthenticatedUser) {
    return this.sitesFeed.trackFeedEvent(dto, user);
  }

  submitFeedFeedback(siteId: string, dto: SubmitFeedFeedbackDto, user: AuthenticatedUser) {
    return this.sitesFeed.submitFeedFeedback(siteId, dto, user);
  }

  updateStatus(siteId: string, dto: UpdateSiteStatusDto, admin: AuthenticatedUser) {
    return this.sitesAdmin.updateStatus(siteId, dto, admin);
  }

  assertSiteEligibleForEcoAction(siteId: string) {
    return this.sitesAdmin.assertSiteEligibleForEcoAction(siteId);
  }

  private async getEngagementSnapshot(siteId: string, userId: string) {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      include: {
        votes: {
          where: { userId },
          select: { id: true },
          take: 1,
        },
        saves: {
          where: { userId },
          select: { id: true },
          take: 1,
        },
      },
    });
    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }
    return {
      siteId,
      upvotesCount: site.upvotesCount,
      commentsCount: site.commentsCount,
      savesCount: site.savesCount,
      sharesCount: site.sharesCount,
      isUpvotedByMe: site.votes.length > 0,
      isSavedByMe: site.saves.length > 0,
    };
  }

  private emitSiteNotification(
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
        this.eventEmitter.emit('notification.send', {
          recipientUserIds: recipientIds,
          title: type === 'UPVOTE' ? 'New upvote' : type === 'COMMENT' ? 'New comment' : 'Site update',
          body,
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
