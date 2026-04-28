import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';

export type SiteWithDetailRelations = Prisma.SiteGetPayload<{
  include: {
    reports: {
      include: {
        reporter: {
          select: { firstName: true; lastName: true; avatarObjectKey: true };
        };
        coReporters: {
          include: {
            user: {
              select: { firstName: true; lastName: true; avatarObjectKey: true };
            };
          };
        };
      };
    };
    events: true;
  };
}>;

@Injectable()
export class SiteDetailRepository {
  constructor(private readonly prisma: PrismaService) {}

  findByIdWithRelations(siteId: string, reportsTake: number, eventsTake: number) {
    return this.prisma.site.findUnique({
      where: { id: siteId },
      include: {
        reports: {
          orderBy: { createdAt: 'desc' },
          take: reportsTake,
          include: {
            reporter: {
              select: { firstName: true, lastName: true, avatarObjectKey: true },
            },
            coReporters: {
              include: {
                user: { select: { firstName: true, lastName: true, avatarObjectKey: true } },
              },
            },
          },
        },
        events: {
          orderBy: { scheduledAt: 'asc' },
          take: eventsTake,
        },
      },
    });
  }

  countReports(siteId: string) {
    return this.prisma.report.count({ where: { siteId } });
  }

  countEvents(siteId: string) {
    return this.prisma.cleanupEvent.count({ where: { siteId } });
  }

  findVoteBySiteAndUser(siteId: string, userId: string) {
    return this.prisma.siteVote.findUnique({
      where: { siteId_userId: { siteId, userId } },
      select: { id: true },
    });
  }

  findSaveBySiteAndUser(siteId: string, userId: string) {
    return this.prisma.siteSave.findUnique({
      where: { siteId_userId: { siteId, userId } },
      select: { id: true },
    });
  }
}
