import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';

export type SiteWithDetailRelations = Prisma.SiteGetPayload<{
  include: {
    heroReport: {
      select: {
        id: true;
        reporterId: true;
        mediaUrls: true;
        reporter: {
          select: { firstName: true; lastName: true; avatarObjectKey: true; status: true };
        };
      };
    };
    reports: {
      include: {
        reporter: {
          select: { firstName: true; lastName: true; avatarObjectKey: true; status: true };
        };
        coReporters: {
          include: {
            user: {
              select: { firstName: true; lastName: true; avatarObjectKey: true; status: true };
            };
          };
        };
      };
    };
    events: {
      select: {
        id: true;
        title: true;
        scheduledAt: true;
        lifecycleStatus: true;
        organizer: { select: { id: true; firstName: true; lastName: true; status: true } };
      };
    };
  };
}>;

@Injectable()
export class SiteDetailRepository {
  constructor(private readonly prisma: PrismaService) {}

  findByIdWithRelations(siteId: string, reportsTake: number, eventsTake: number) {
    return this.prisma.site.findUnique({
      where: { id: siteId },
      include: {
        heroReport: {
          select: {
            id: true,
            reporterId: true,
            mediaUrls: true,
            reporter: {
              select: { firstName: true, lastName: true, avatarObjectKey: true, status: true },
            },
          },
        },
        reports: {
          orderBy: { createdAt: 'desc' },
          take: reportsTake,
          include: {
            reporter: {
              select: { firstName: true, lastName: true, avatarObjectKey: true, status: true },
            },
            coReporters: {
              include: {
                user: {
                  select: { firstName: true, lastName: true, avatarObjectKey: true, status: true },
                },
              },
            },
          },
        },
        events: {
          orderBy: { scheduledAt: 'asc' },
          take: eventsTake,
          select: {
            id: true,
            title: true,
            scheduledAt: true,
            lifecycleStatus: true,
            organizer: {
              select: { id: true, firstName: true, lastName: true, status: true },
            },
          },
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

  findSiteStatusById(siteId: string) {
    return this.prisma.site.findUnique({
      where: { id: siteId },
      select: { id: true, status: true },
    });
  }

  async viewerCanAccessReportedSite(siteId: string, viewerUserId: string): Promise<boolean> {
    const count = await this.prisma.report.count({
      where: {
        siteId,
        OR: [
          { reporterId: viewerUserId },
          { coReporters: { some: { userId: viewerUserId } } },
        ],
      },
    });
    return count > 0;
  }
}
