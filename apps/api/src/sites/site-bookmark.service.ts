import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SiteBookmarkService {
  constructor(private readonly prisma: PrismaService) {}

  private async ensureSiteExists(siteId: string): Promise<void> {
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

  async save(siteId: string, userId: string): Promise<void> {
    await this.ensureSiteExists(siteId);
    await this.prisma.$transaction(async (tx) => {
      const created = await tx.siteSave.createMany({
        data: [{ siteId, userId }],
        skipDuplicates: true,
      });
      if (created.count > 0) {
        await tx.site.update({
          where: { id: siteId },
          data: { savesCount: { increment: 1 } },
        });
      }
    });
  }

  async unsave(siteId: string, userId: string): Promise<void> {
    await this.ensureSiteExists(siteId);
    await this.prisma.$transaction(async (tx) => {
      const deleted = await tx.siteSave.deleteMany({
        where: { siteId, userId },
      });
      if (deleted.count > 0) {
        await tx.site.update({
          where: { id: siteId },
          data: { savesCount: { decrement: deleted.count } },
        });
      }
    });
  }
}
