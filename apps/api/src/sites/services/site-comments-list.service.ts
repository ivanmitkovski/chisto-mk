import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ListSiteCommentsQueryDto, SiteCommentsSort } from '../dto/list-site-comments-query.dto';
import { SiteEngagementService } from './site-engagement.service';
import { SiteCommentsCountService } from './site-comments-count.service';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import { ModerationService } from '../../moderation/services/moderation.service';
import type { SiteCommentTreeNode } from '../types/site-comments.types';
import { resolveActorIdentity } from '../../common/projections/public-identity.projection';

@Injectable()
export class SiteCommentsListService {
  private static readonly INLINE_BRANCH_REPLY_CAP = 20;
  private static readonly MAX_COMMENTS_FOR_TREE = 500;

  constructor(
    private readonly prisma: PrismaService,
    private readonly siteEngagement: SiteEngagementService,
    private readonly reportsUpload: ReportsUploadService,
    private readonly moderation: ModerationService,
    private readonly siteCommentsCount: SiteCommentsCountService,
  ) {}

  private async blockedAuthorFilter(
    user?: AuthenticatedUser,
  ): Promise<{ authorId?: { notIn: string[] } }> {
    if (!user) {
      return {};
    }
    const blockedIds = await this.moderation.blockedUserIdsFor(user.userId);
    if (blockedIds.length === 0) {
      return {};
    }
    return { authorId: { notIn: blockedIds } };
  }

  async findSiteComments(
    siteId: string,
    query: ListSiteCommentsQueryDto,
    user?: AuthenticatedUser,
  ): Promise<{
    data: SiteCommentTreeNode[];
    meta: { page: number; limit: number; total: number; engagementTotal: number; truncated?: boolean };
  }> {
    await this.siteEngagement.ensureSiteExists(siteId);
    const blockedFilter = await this.blockedAuthorFilter(user);
    const baseWhere = { siteId, isDeleted: false, ...blockedFilter };

    if (query.parentId) {
      const where = { ...baseWhere, parentId: query.parentId };
      const [total, comments, engagementTotal] = await Promise.all([
        this.prisma.siteComment.count({ where }),
        this.prisma.siteComment.findMany({
          where,
          orderBy: { createdAt: 'desc' },
          skip: (query.page - 1) * query.limit,
          take: query.limit,
          include: {
            author: {
              select: { firstName: true, lastName: true, avatarObjectKey: true, status: true },
            },
            likes: user
              ? {
                  where: { userId: user.userId },
                  select: { id: true },
                  take: 1,
                }
              : false,
          },
        }),
        this.siteCommentsCount.countVisible(siteId, user),
      ]);
      const ordered =
        query.sort === SiteCommentsSort.TOP
          ? [...comments].sort((a, b) => this.compareCommentsTop(a, b))
          : comments;
      const avatarUrlByAuthorId = await this.resolveAuthorAvatarUrls(ordered);
      return {
        data: ordered.map((comment) => {
          const authorIdentity = resolveActorIdentity(comment.author, {
            actorUserId: comment.authorId,
          });
          return {
          id: comment.id,
          parentId: comment.parentId,
          body: comment.body,
          createdAt: comment.createdAt.toISOString(),
          authorId: comment.authorId,
          authorName: authorIdentity.displayName ?? '',
          authorIsDeleted: authorIdentity.isDeleted,
          authorAvatarUrl:
            comment.authorId != null
              ? (avatarUrlByAuthorId.get(comment.authorId) ?? null)
              : null,
          likesCount: comment.likesCount,
          isLikedByMe: Array.isArray(comment.likes) && comment.likes.length > 0,
          replies: [],
          repliesCount: 0,
        };
        }),
        meta: { page: query.page, limit: query.limit, total, engagementTotal },
      };
    }

    type CommentRow = {
      id: string;
      parentId: string | null;
      body: string;
      createdAt: Date;
      authorId: string | null;
      likesCount: number;
      author: {
        firstName: string;
        lastName: string;
        avatarObjectKey: string | null;
        status?: import('../../prisma-client').UserStatus;
      } | null;
      likes?: Array<{ id: string }> | false;
    };

    const [allComments, total, engagementTotal] = await Promise.all([
      this.prisma.siteComment.findMany({
        where: baseWhere,
        orderBy: { createdAt: 'asc' },
        take: SiteCommentsListService.MAX_COMMENTS_FOR_TREE,
        include: {
          author: {
            select: { firstName: true, lastName: true, avatarObjectKey: true, status: true },
          },
          likes: user
            ? {
                where: { userId: user.userId },
                select: { id: true },
                take: 1,
              }
            : false,
        },
      }) as Promise<CommentRow[]>,
      this.prisma.siteComment.count({
        where: { ...baseWhere, parentId: null },
      }),
      this.siteCommentsCount.countVisible(siteId, user),
    ]);

    const rootRows = allComments.filter((c) => c.parentId == null);
    const sortedRoots =
      query.sort === SiteCommentsSort.TOP
        ? [...rootRows].sort((a, b) => this.compareCommentsTop(a, b))
        : [...rootRows].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    const skipRoots = (query.page - 1) * query.limit;
    const rootComments = sortedRoots.slice(skipRoots, skipRoots + query.limit);

    const byParent = new Map<string, CommentRow[]>();
    for (const comment of allComments) {
      if (!comment.parentId) continue;
      const list = byParent.get(comment.parentId) ?? [];
      list.push(comment);
      byParent.set(comment.parentId, list);
    }
    const avatarUrlByAuthorId = await this.resolveAuthorAvatarUrls(allComments);

    const mapNode = (comment: CommentRow): SiteCommentTreeNode => {
      const rawChildren = byParent.get(comment.id) ?? [];
      const sortedDb =
        query.sort === SiteCommentsSort.TOP
          ? [...rawChildren].sort((a, b) => this.compareCommentsTop(a, b))
          : [...rawChildren].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
      const fullCount = sortedDb.length;
      const pageDb = sortedDb.slice(0, SiteCommentsListService.INLINE_BRANCH_REPLY_CAP);
      const replies = pageDb.map(mapNode);
      const orderedReplies =
        query.sort === SiteCommentsSort.TOP
          ? [...replies].sort((a, b) => this.compareCommentNodesTop(a, b))
          : replies.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
      const authorIdentity = resolveActorIdentity(comment.author, {
        actorUserId: comment.authorId,
      });
      return {
        id: comment.id,
        parentId: comment.parentId,
        body: comment.body,
        createdAt: comment.createdAt.toISOString(),
        authorId: comment.authorId,
        authorName: authorIdentity.displayName ?? '',
        authorIsDeleted: authorIdentity.isDeleted,
        authorAvatarUrl:
          comment.authorId != null
            ? (avatarUrlByAuthorId.get(comment.authorId) ?? null)
            : null,
        likesCount: comment.likesCount,
        isLikedByMe:
          Array.isArray((comment as { likes?: Array<{ id: string }> }).likes) &&
          ((comment as { likes?: Array<{ id: string }> }).likes?.length ?? 0) > 0,
        replies: orderedReplies,
        repliesCount: fullCount,
      };
    };

    const roots =
      query.sort === SiteCommentsSort.TOP
        ? [...rootComments].sort((a, b) => this.compareCommentsTop(a, b))
        : rootComments;

    return {
      data: roots.map(mapNode),
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        engagementTotal,
        truncated: allComments.length >= SiteCommentsListService.MAX_COMMENTS_FOR_TREE,
      },
    };
  }

  private compareCommentsTop(
    a: { likesCount: number; createdAt: Date; id: string },
    b: { likesCount: number; createdAt: Date; id: string },
  ): number {
    const scoreB = this.computeCommentTopScore(b.likesCount, b.createdAt, b.id);
    const scoreA = this.computeCommentTopScore(a.likesCount, a.createdAt, a.id);
    return scoreB - scoreA;
  }

  private compareCommentNodesTop(a: SiteCommentTreeNode, b: SiteCommentTreeNode): number {
    const scoreB = this.computeCommentTopScore(
      b.likesCount + b.repliesCount,
      new Date(b.createdAt),
      b.id,
    );
    const scoreA = this.computeCommentTopScore(
      a.likesCount + a.repliesCount,
      new Date(a.createdAt),
      a.id,
    );
    return scoreB - scoreA;
  }

  private computeCommentTopScore(baseSignals: number, createdAt: Date, id: string): number {
    const ageHours = Math.max(0, (Date.now() - createdAt.getTime()) / (1000 * 60 * 60));
    const freshness = Math.exp(-Math.log(2) * (ageHours / 24));
    const engagement = Math.log1p(Math.max(0, baseSignals));
    const jitter = this.commentJitter(id);
    return freshness * 0.55 + engagement * 0.45 + jitter;
  }

  private commentJitter(id: string): number {
    let hash = 0;
    for (let i = 0; i < id.length; i++) {
      hash = (hash * 31 + id.charCodeAt(i)) | 0;
    }
    return ((Math.abs(hash) % 1000) / 1000 - 0.5) * 0.01;
  }

  private async resolveAuthorAvatarUrls(
    comments: Array<{
      authorId: string | null;
      author: { avatarObjectKey: string | null } | null;
    }>,
  ): Promise<Map<string, string | null>> {
    const avatarByAuthorId = new Map<string, string | null>();
    const signingTasks = new Map<string, Promise<string | null>>();
    for (const comment of comments) {
      if (comment.authorId == null) {
        continue;
      }
      const key = comment.author?.avatarObjectKey;
      if (!key || key.trim().length === 0) {
        avatarByAuthorId.set(comment.authorId, null);
        continue;
      }
      if (!signingTasks.has(key)) {
        signingTasks.set(key, this.reportsUpload.signPrivateObjectKey(key));
      }
    }

    const signedByKey = new Map<string, string | null>();
    await Promise.all(
      [...signingTasks.entries()].map(async ([key, task]) => {
        signedByKey.set(key, await task);
      }),
    );
    for (const comment of comments) {
      if (comment.authorId == null) {
        continue;
      }
      const key = comment.author?.avatarObjectKey;
      if (!key || key.trim().length === 0) {
        avatarByAuthorId.set(comment.authorId, null);
      } else {
        avatarByAuthorId.set(comment.authorId, signedByKey.get(key) ?? null);
      }
    }
    return avatarByAuthorId;
  }
}
