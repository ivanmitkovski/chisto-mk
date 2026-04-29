import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SiteUpvotesRepository {
  constructor(private readonly prisma: PrismaService) {}

  countBySiteId(siteId: string): Promise<number> {
    return this.prisma.siteVote.count({ where: { siteId } });
  }

  findPageBySiteId(input: { siteId: string; skip: number; take: number }) {
    return this.prisma.siteVote.findMany({
      where: { siteId: input.siteId },
      orderBy: { createdAt: 'desc' },
      skip: input.skip,
      take: input.take,
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarObjectKey: true,
          },
        },
      },
    });
  }
}
