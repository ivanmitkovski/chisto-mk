import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { CreateSiteCommentDto } from '../dto/create-site-comment.dto';
import { UpdateSiteCommentDto } from '../dto/update-site-comment.dto';
import { SiteEngagementService } from './site-engagement.service';
import { SiteCommentsCountService } from './site-comments-count.service';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import { resolveActorIdentity } from '../../common/projections/public-identity.projection';

@Injectable()
export class SiteCommentsMutationsService {
  private static readonly COMMENT_DELETE_MAX_DEPTH = 32;
  private static readonly COMMENT_DELETE_MAX_DESCENDANTS = 500;

  constructor(
    private readonly prisma: PrismaService,
    private readonly siteEngagement: SiteEngagementService,
    private readonly siteCommentsCount: SiteCommentsCountService,
    private readonly reportsUpload: ReportsUploadService,
  ) {}

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
            select: { firstName: true, lastName: true, avatarObjectKey: true, status: true },
          },
        },
      });
      await tx.site.update({
        where: { id: siteId },
        data: { commentsCount: { increment: 1 } },
      });
      return comment;
    });
    const authorIdentity = resolveActorIdentity(result.author, {
      actorUserId: result.authorId,
    });
    return {
      id: result.id,
      parentId: result.parentId,
      body: result.body,
      createdAt: result.createdAt.toISOString(),
      authorId: result.authorId,
      authorName: authorIdentity.displayName ?? '',
      authorIsDeleted: authorIdentity.isDeleted,
      authorAvatarUrl: await this.reportsUpload.signPrivateObjectKey(
        result.author?.avatarObjectKey ?? null,
      ),
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
        author: { select: { firstName: true, lastName: true, status: true } },
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
          select: { firstName: true, lastName: true, avatarObjectKey: true, status: true },
        },
      },
    });
    const authorIdentity = resolveActorIdentity(updated.author, {
      actorUserId: updated.authorId,
    });
    return {
      id: updated.id,
      parentId: updated.parentId,
      body: updated.body,
      createdAt: updated.createdAt.toISOString(),
      authorId: updated.authorId,
      authorName: authorIdentity.displayName ?? '',
      authorIsDeleted: authorIdentity.isDeleted,
      authorAvatarUrl: await this.reportsUpload.signPrivateObjectKey(
        updated.author?.avatarObjectKey ?? null,
      ),
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
      let depth = 0;
      while (
        frontier.length > 0 &&
        depth < SiteCommentsMutationsService.COMMENT_DELETE_MAX_DEPTH &&
        toDelete.size < SiteCommentsMutationsService.COMMENT_DELETE_MAX_DESCENDANTS
      ) {
        const children = await tx.siteComment.findMany({
          where: { siteId, isDeleted: false, parentId: { in: frontier } },
          select: { id: true },
        });
        frontier = [];
        for (const row of children) {
          if (toDelete.size >= SiteCommentsMutationsService.COMMENT_DELETE_MAX_DESCENDANTS) {
            break;
          }
          if (!toDelete.has(row.id)) {
            toDelete.add(row.id);
            frontier.push(row.id);
          }
        }
        depth += 1;
      }
      const ids = [...toDelete];
      await tx.siteCommentLike.deleteMany({
        where: { commentId: { in: ids } },
      });
      const updated = await tx.siteComment.updateMany({
        where: { id: { in: ids }, isDeleted: false },
        data: { isDeleted: true },
      });
      return updated.count;
    });
    if (affectedCount > 0) {
      await this.siteCommentsCount.reconcileGlobal(siteId);
    }
    return { commentId, deletedCount: affectedCount };
  }
}
