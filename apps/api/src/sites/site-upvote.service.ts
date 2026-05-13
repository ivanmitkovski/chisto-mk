import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SiteUpvoteService {
  constructor(private readonly prisma: PrismaService) {}

  async ensureSiteExists(siteId: string): Promise<void> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      select: { id: true },
    });
    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }
  }

  async upvote(siteId: string, userId: string): Promise<void> {
    await this.ensureSiteExists(siteId);
    await this.prisma.$transaction(async (tx) => {
      const created = await tx.siteVote.createMany({
        data: [{ siteId, userId }],
        skipDuplicates: true,
      });
      if (created.count > 0) {
        await tx.site.update({
          where: { id: siteId },
          data: { upvotesCount: { increment: 1 } },
        });
      }
    });
  }

  async removeUpvote(siteId: string, userId: string): Promise<void> {
    await this.ensureSiteExists(siteId);
    await this.prisma.$transaction(async (tx) => {
      const deleted = await tx.siteVote.deleteMany({
        where: { siteId, userId },
      });
      if (deleted.count > 0) {
        await tx.site.update({
          where: { id: siteId },
          data: { upvotesCount: { decrement: deleted.count } },
        });
      }
    });
  }
}
