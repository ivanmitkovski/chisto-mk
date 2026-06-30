import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ModerationService } from '../../moderation/services/moderation.service';

@Injectable()
export class SiteCommentsCountService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly moderation: ModerationService,
  ) {}

  async reconcileGlobal(siteId: string): Promise<number> {
    const actualCount = await this.prisma.siteComment.count({
      where: { siteId, isDeleted: false },
    });
    await this.prisma.site.update({
      where: { id: siteId },
      data: { commentsCount: actualCount },
    });
    return actualCount;
  }

  async reconcileSitesForAuthor(userId: string): Promise<void> {
    const rows = await this.prisma.siteComment.findMany({
      where: { authorId: userId },
      select: { siteId: true },
      distinct: ['siteId'],
    });
    await Promise.all(rows.map((row) => this.reconcileGlobal(row.siteId)));
  }

  async countVisible(siteId: string, user?: AuthenticatedUser): Promise<number> {
    const where = await this.visibleWhere(siteId, user);
    return this.prisma.siteComment.count({ where });
  }

  async countVisibleBatch(
    siteIds: string[],
    user?: AuthenticatedUser,
  ): Promise<Map<string, number>> {
    const unique = [...new Set(siteIds.filter((id) => id.trim().length > 0))];
    const out = new Map<string, number>();
    if (unique.length === 0) {
      return out;
    }

    const blockedFilter = await this.blockedAuthorFilter(user);
    const rows = await this.prisma.siteComment.groupBy({
      by: ['siteId'],
      where: {
        siteId: { in: unique },
        isDeleted: false,
        ...blockedFilter,
      },
      _count: { _all: true },
    });
    for (const row of rows) {
      out.set(row.siteId, row._count._all);
    }
    for (const siteId of unique) {
      if (!out.has(siteId)) {
        out.set(siteId, 0);
      }
    }
    return out;
  }

  private async visibleWhere(siteId: string, user?: AuthenticatedUser) {
    return {
      siteId,
      isDeleted: false,
      ...(await this.blockedAuthorFilter(user)),
    };
  }

  private async blockedAuthorFilter(
    user?: AuthenticatedUser,
  ): Promise<{ authorId?: { notIn: string[] } }> {
    if (!user?.userId) {
      return {};
    }
    const blockedIds = await this.moderation.blockedUserIdsFor(user.userId);
    if (blockedIds.length === 0) {
      return {};
    }
    return { authorId: { notIn: blockedIds } };
  }

}
