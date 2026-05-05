import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ListSiteCommentsQueryDto, SiteCommentsSort } from './dto/list-site-comments-query.dto';
import { CreateSiteCommentDto } from './dto/create-site-comment.dto';
import { UpdateSiteCommentDto } from './dto/update-site-comment.dto';
import { SiteEngagementService } from './site-engagement.service';
import { ReportsUploadService } from '../reports/reports-upload.service';

export type SiteCommentTreeNode = {
  id: string;
  parentId: string | null;
  body: string;
  createdAt: string;
  authorId: string;
  authorName: string;
  authorAvatarUrl?: string | null;
  likesCount: number;
  isLikedByMe: boolean;
  replies: SiteCommentTreeNode[];
  repliesCount: number;
};

@Injectable()
export class SiteCommentsService {
  /** Max direct replies inlined per parent in tree mode; use `parentId` + `page` to load the rest. */
  private static readonly INLINE_BRANCH_REPLY_CAP = 20;

  /** Safety cap for in-memory tree build (single-query path); sites above this see truncated roots only. */
  private static readonly MAX_COMMENTS_FOR_TREE = 15_000;

  constructor(
    private readonly prisma: PrismaService,
    private readonly siteEngagement: SiteEngagementService,
    private readonly reportsUpload: ReportsUploadService,
  ) {}

  async findSiteComments(
    siteId: string,
    query: ListSiteCommentsQueryDto,
    user?: AuthenticatedUser,
  ): Promise<{
    data: SiteCommentTreeNode[];
    meta: { page: number; limit: number; total: number; truncated?: boolean };
  }> {
    await this.siteEngagement.ensureSiteExists(siteId);
    const baseWhere = { siteId, isDeleted: false };

    if (query.parentId) {
      const where = { ...baseWhere, parentId: query.parentId };
      const [total, comments] = await Promise.all([
        this.prisma.siteComment.count({ where }),
        this.prisma.siteComment.findMany({
          where,
          orderBy: { createdAt: 'desc' },
          skip: (query.page - 1) * query.limit,
          take: query.limit,
          include: {
            author: {
              select: { firstName: true, lastName: true, avatarObjectKey: true },
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
      ]);
      const ordered =
        query.sort === SiteCommentsSort.TOP
          ? [...comments].sort((a, b) => this.compareCommentsTop(a, b))
          : comments;
      const avatarUrlByAuthorId = await this.resolveAuthorAvatarUrls(ordered);
      return {
        data: ordered.map((comment) => ({
          id: comment.id,
          parentId: comment.parentId,
          body: comment.body,
          createdAt: comment.createdAt.toISOString(),
          authorId: comment.authorId,
          authorName: `${comment.author.firstName} ${comment.author.lastName}`.trim(),
          authorAvatarUrl: avatarUrlByAuthorId.get(comment.authorId) ?? null,
          likesCount: comment.likesCount,
          isLikedByMe: Array.isArray(comment.likes) && comment.likes.length > 0,
          replies: [],
          repliesCount: 0,
        })),
        meta: { page: query.page, limit: query.limit, total },
      };
    }

    type CommentRow = {
      id: string;
      parentId: string | null;
      body: string;
      createdAt: Date;
      authorId: string;
      likesCount: number;
      author: { firstName: string; lastName: string; avatarObjectKey: string | null };
      likes?: Array<{ id: string }> | false;
    };

    const [allComments, total] = await Promise.all([
      this.prisma.siteComment.findMany({
        where: baseWhere,
        orderBy: { createdAt: 'asc' },
        take: SiteCommentsService.MAX_COMMENTS_FOR_TREE,
        include: {
          author: {
            select: { firstName: true, lastName: true, avatarObjectKey: true },
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
      const pageDb = sortedDb.slice(0, SiteCommentsService.INLINE_BRANCH_REPLY_CAP);
      const replies = pageDb.map(mapNode);
      const orderedReplies =
        query.sort === SiteCommentsSort.TOP
          ? [...replies].sort((a, b) => this.compareCommentNodesTop(a, b))
          : replies.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
      return {
        id: comment.id,
        parentId: comment.parentId,
        body: comment.body,
        createdAt: comment.createdAt.toISOString(),
        authorId: comment.authorId,
        authorName: `${comment.author.firstName} ${comment.author.lastName}`.trim(),
        authorAvatarUrl: avatarUrlByAuthorId.get(comment.authorId) ?? null,
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
        truncated: allComments.length >= SiteCommentsService.MAX_COMMENTS_FOR_TREE,
      },
    };
  }

  async createSiteComment(siteId: string, dto: CreateSiteCommentDto, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const body = dto.body.trim();
    if (!body) {
      throw new BadRequestException({
        code: 'COMMENT_EMPTY',
        message: 'Comment body cannot be empty.',
      });
    }
    if (dto.parentId) {
      const parent = await this.prisma.siteComment.findUnique({
        where: { id: dto.parentId },
        select: { id: true, siteId: true, isDeleted: true },
      });
      if (!parent || parent.isDeleted || parent.siteId !== siteId) {
        throw new BadRequestException({
          code: 'INVALID_PARENT_COMMENT',
          message: 'Parent comment is invalid for this site.',
        });
      }
    }
    const result = await this.prisma.$transaction(async (tx) => {
      const comment = await tx.siteComment.create({
        data: { siteId, authorId: user.userId, body, parentId: dto.parentId ?? null },
        include: {
          author: {
            select: { firstName: true, lastName: true, avatarObjectKey: true },
          },
        },
      });
      await tx.site.update({
        where: { id: siteId },
        data: { commentsCount: { increment: 1 } },
      });
      return comment;
    });
    return {
      id: result.id,
      parentId: result.parentId,
      body: result.body,
      createdAt: result.createdAt.toISOString(),
      authorId: result.authorId,
      authorName: `${result.author.firstName} ${result.author.lastName}`.trim(),
      authorAvatarUrl: await this.reportsUpload.signPrivateObjectKey(result.author.avatarObjectKey),
      likesCount: result.likesCount,
      isLikedByMe: false,
      replies: [],
      repliesCount: 0,
    };
  }

  async likeSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const comment = await this.prisma.siteComment.findUnique({
      where: { id: commentId },
      select: { id: true, siteId: true, isDeleted: true, likesCount: true },
    });
    if (!comment || comment.isDeleted || comment.siteId !== siteId) {
      throw new NotFoundException({
        code: 'COMMENT_NOT_FOUND',
        message: 'Comment not found for this site.',
      });
    }
    const result = await this.prisma.$transaction(async (tx) => {
      const existing = await tx.siteCommentLike.findUnique({
        where: { commentId_userId: { commentId, userId: user.userId } },
        select: { id: true },
      });
      if (!existing) {
        await tx.siteCommentLike.create({
          data: { commentId, userId: user.userId },
        });
        return tx.siteComment.update({
          where: { id: commentId },
          data: { likesCount: { increment: 1 } },
          select: { id: true, likesCount: true },
        });
      }
      return tx.siteComment.findUniqueOrThrow({
        where: { id: commentId },
        select: { id: true, likesCount: true },
      });
    });
    return { commentId: result.id, likesCount: result.likesCount, isLikedByMe: true };
  }

  async unlikeSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const comment = await this.prisma.siteComment.findUnique({
      where: { id: commentId },
      select: { id: true, siteId: true, isDeleted: true, likesCount: true },
    });
    if (!comment || comment.isDeleted || comment.siteId !== siteId) {
      throw new NotFoundException({
        code: 'COMMENT_NOT_FOUND',
        message: 'Comment not found for this site.',
      });
    }
    const result = await this.prisma.$transaction(async (tx) => {
      const deleted = await tx.siteCommentLike.deleteMany({
        where: { commentId, userId: user.userId },
      });
      if (deleted.count > 0) {
        return tx.siteComment.update({
          where: { id: commentId },
          data: { likesCount: { decrement: 1 } },
          select: { id: true, likesCount: true },
        });
      }
      return tx.siteComment.findUniqueOrThrow({
        where: { id: commentId },
        select: { id: true, likesCount: true },
      });
    });
    return { commentId: result.id, likesCount: Math.max(0, result.likesCount), isLikedByMe: false };
  }

  async updateSiteComment(
    siteId: string,
    commentId: string,
    dto: UpdateSiteCommentDto,
    user: AuthenticatedUser,
  ) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const body = dto.body.trim();
    if (!body) {
      throw new BadRequestException({
        code: 'COMMENT_EMPTY',
        message: 'Comment body cannot be empty.',
      });
    }
    const comment = await this.prisma.siteComment.findUnique({
      where: { id: commentId },
      select: {
        id: true,
        siteId: true,
        authorId: true,
        isDeleted: true,
        parentId: true,
        createdAt: true,
        likesCount: true,
        author: { select: { firstName: true, lastName: true } },
      },
    });
    if (!comment || comment.isDeleted || comment.siteId !== siteId) {
      throw new NotFoundException({
        code: 'COMMENT_NOT_FOUND',
        message: 'Comment not found for this site.',
      });
    }
    if (comment.authorId !== user.userId) {
      throw new ForbiddenException({
        code: 'COMMENT_FORBIDDEN',
        message: 'You can edit only your own comments.',
      });
    }
    const updated = await this.prisma.siteComment.update({
      where: { id: commentId },
      data: { body },
      include: {
        author: {
          select: { firstName: true, lastName: true, avatarObjectKey: true },
        },
      },
    });
    return {
      id: updated.id,
      parentId: updated.parentId,
      body: updated.body,
      createdAt: updated.createdAt.toISOString(),
      authorId: updated.authorId,
      authorName: `${updated.author.firstName} ${updated.author.lastName}`.trim(),
      authorAvatarUrl: await this.reportsUpload.signPrivateObjectKey(updated.author.avatarObjectKey),
      likesCount: updated.likesCount,
      isLikedByMe: false,
      replies: [],
      repliesCount: 0,
    };
  }

  async deleteSiteComment(siteId: string, commentId: string, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const comment = await this.prisma.siteComment.findUnique({
      where: { id: commentId },
      select: { id: true, siteId: true, authorId: true, isDeleted: true },
    });
    if (!comment || comment.isDeleted || comment.siteId !== siteId) {
      throw new NotFoundException({
        code: 'COMMENT_NOT_FOUND',
        message: 'Comment not found for this site.',
      });
    }
    if (comment.authorId !== user.userId) {
      throw new ForbiddenException({
        code: 'COMMENT_FORBIDDEN',
        message: 'You can delete only your own comments.',
      });
    }
    const affectedCount = await this.prisma.$transaction(async (tx) => {
      const toDelete = new Set<string>([commentId]);
      let frontier: string[] = [commentId];
      while (frontier.length > 0) {
        const children = await tx.siteComment.findMany({
          where: { siteId, isDeleted: false, parentId: { in: frontier } },
          select: { id: true },
        });
        frontier = [];
        for (const row of children) {
          if (!toDelete.has(row.id)) {
            toDelete.add(row.id);
            frontier.push(row.id);
          }
        }
      }
      const ids = [...toDelete];
      await tx.siteCommentLike.deleteMany({
        where: { commentId: { in: ids } },
      });
      const updated = await tx.siteComment.updateMany({
        where: { id: { in: ids }, isDeleted: false },
        data: { isDeleted: true },
      });
      if (updated.count > 0) {
        const actualCount = await tx.siteComment.count({
          where: { siteId, isDeleted: false },
        });
        await tx.site.update({
          where: { id: siteId },
          data: { commentsCount: actualCount },
        });
      }
      return updated.count;
    });
    return { commentId, deletedCount: affectedCount };
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
      authorId: string;
      author: { avatarObjectKey: string | null };
    }>,
  ): Promise<Map<string, string | null>> {
    const avatarByAuthorId = new Map<string, string | null>();
    const signingTasks = new Map<string, Promise<string | null>>();
    for (const comment of comments) {
      const key = comment.author.avatarObjectKey;
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
      const key = comment.author.avatarObjectKey;
      if (!key || key.trim().length === 0) {
        avatarByAuthorId.set(comment.authorId, null);
      } else {
        avatarByAuthorId.set(comment.authorId, signedByKey.get(key) ?? null);
      }
    }
    return avatarByAuthorId;
  }
}
