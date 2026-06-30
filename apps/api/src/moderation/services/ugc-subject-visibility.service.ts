import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthSessionRevocationService } from '../../auth/services/auth-session-revocation.service';

@Injectable()
export class UgcSubjectVisibilityService {
  private static readonly SUBTREE_MAX_DEPTH = 32;
  private static readonly SUBTREE_MAX_NODES = 500;

  constructor(
    private readonly prisma: PrismaService,
    private readonly sessionRevocation: AuthSessionRevocationService,
  ) {}

  async resolveContentStatus(subjectType: string, subjectId: string): Promise<string> {
    switch (subjectType) {
      case 'site_comment': {
        const row = await this.prisma.siteComment.findUnique({
          where: { id: subjectId },
          select: { isDeleted: true },
        });
        return row?.isDeleted ? 'hidden' : 'visible';
      }
      case 'event_chat_message': {
        const row = await this.prisma.eventChatMessage.findUnique({
          where: { id: subjectId },
          select: { deletedAt: true },
        });
        return row?.deletedAt ? 'hidden' : 'visible';
      }
      case 'site': {
        const row = await this.prisma.site.findUnique({
          where: { id: subjectId },
          select: { isArchivedByAdmin: true },
        });
        return row?.isArchivedByAdmin ? 'hidden' : 'visible';
      }
      case 'user': {
        const row = await this.prisma.user.findUnique({
          where: { id: subjectId },
          select: { status: true },
        });
        return row?.status === 'SUSPENDED' ? 'hidden' : 'visible';
      }
      case 'event': {
        const row = await this.prisma.cleanupEvent.findUnique({
          where: { id: subjectId },
          select: { status: true },
        });
        return row?.status === 'DECLINED' ? 'hidden' : 'visible';
      }
      default:
        return 'unknown';
    }
  }

  async applySubjectVisibility(subjectType: string, subjectId: string, hidden: boolean): Promise<void> {
    switch (subjectType) {
      case 'site_comment':
        await this.applySiteCommentVisibility(subjectId, hidden);
        return;
      case 'event_chat_message':
        await this.prisma.eventChatMessage.updateMany({
          where: { id: subjectId },
          data: { deletedAt: hidden ? new Date() : null },
        });
        return;
      case 'site':
        await this.prisma.site.updateMany({
          where: { id: subjectId },
          data: {
            isArchivedByAdmin: hidden,
            archivedAt: hidden ? new Date() : null,
          },
        });
        return;
      case 'user':
        await this.prisma.user.updateMany({
          where: { id: subjectId },
          data: { status: hidden ? 'SUSPENDED' : 'ACTIVE' },
        });
        if (hidden) {
          await this.sessionRevocation.revokeAllForUser(subjectId, 'status_changed');
        }
        return;
      case 'event':
        await this.prisma.cleanupEvent.updateMany({
          where: { id: subjectId },
          data: { status: hidden ? 'DECLINED' : 'APPROVED' },
        });
        return;
      default:
        throw new BadRequestException({
          code: 'UNSUPPORTED_SUBJECT',
          message: `Cannot ${hidden ? 'hide' : 'restore'} subject type ${subjectType}`,
        });
    }
  }

  /** Hide/restore a comment subtree and reconcile the site's global comment counter. */
  private async applySiteCommentVisibility(commentId: string, hidden: boolean): Promise<void> {
    const root = await this.prisma.siteComment.findUnique({
      where: { id: commentId },
      select: { id: true, siteId: true },
    });
    if (!root) {
      throw new NotFoundException({
        code: 'COMMENT_NOT_FOUND',
        message: 'Comment not found',
      });
    }

    const ids = await this.collectSubtreeIds(root.siteId, root.id);
    if (ids.length === 0) {
      return;
    }

    await this.prisma.siteComment.updateMany({
      where: { id: { in: ids }, siteId: root.siteId },
      data: { isDeleted: hidden },
    });
    const actualCount = await this.prisma.siteComment.count({
      where: { siteId: root.siteId, isDeleted: false },
    });
    await this.prisma.site.update({
      where: { id: root.siteId },
      data: { commentsCount: actualCount },
    });
  }

  private async collectSubtreeIds(siteId: string, rootCommentId: string): Promise<string[]> {
    const toVisit = new Set<string>([rootCommentId]);
    let frontier: string[] = [rootCommentId];
    let depth = 0;

    while (
      frontier.length > 0 &&
      depth < UgcSubjectVisibilityService.SUBTREE_MAX_DEPTH &&
      toVisit.size < UgcSubjectVisibilityService.SUBTREE_MAX_NODES
    ) {
      const children = await this.prisma.siteComment.findMany({
        where: { siteId, parentId: { in: frontier } },
        select: { id: true },
      });
      frontier = [];
      for (const row of children) {
        if (toVisit.size >= UgcSubjectVisibilityService.SUBTREE_MAX_NODES) {
          break;
        }
        if (!toVisit.has(row.id)) {
          toVisit.add(row.id);
          frontier.push(row.id);
        }
      }
      depth += 1;
    }

    return [...toVisit];
  }
}
