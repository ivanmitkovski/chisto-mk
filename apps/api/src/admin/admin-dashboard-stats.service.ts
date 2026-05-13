import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export type AdminRawOverviewBundle = {
  reportGroups: Array<{ status: string; _count: { _all: number } }>;
  siteGroups: Array<{ status: string; _count: { _all: number } }>;
  duplicateGroupsCount: number;
  upcomingEvents: number;
  upcomingEventsList: Array<{
    id: string;
    scheduledAt: Date;
    site: { description: string | null; latitude: number; longitude: number };
  }>;
  pendingEvents: number;
  completedEvents: number;
  usersCount: number;
  usersNewLast7d: number;
  sessionsActive: number;
  reportCountsByDay: Array<{ date: string; count: bigint }>;
  recentLogs: Array<{
    id: string;
    createdAt: Date;
    action: string;
    resourceType: string;
    resourceId: string | null;
    actor: { email: string } | null;
  }>;
  recentFeedDemotions: number;
  rankingCandidates: Array<{
    id: string;
    createdAt: Date;
    updatedAt: Date;
    status: string;
    upvotesCount: number;
    commentsCount: number;
    savesCount: number;
    sharesCount: number;
    reports: Array<{ createdAt: Date; category: string | null; title: string }>;
  }>;
  cleanupParticipantSum: { _sum: { participantCount: number | null } };
};

@Injectable()
export class AdminDashboardStatsService {
  constructor(private readonly prisma: PrismaService) {}

  reportDailyCountsSince(since: Date) {
    return this.prisma.$queryRaw<Array<{ date: string; count: bigint }>>`
      SELECT ("createdAt"::date)::text as date, COUNT(*)::bigint as count
      FROM "Report"
      WHERE "createdAt" >= ${since}
      GROUP BY "createdAt"::date
      ORDER BY date ASC
    `;
  }

  async loadRawOverviewBundle(
    now: Date,
    sevenDaysAgo: Date,
    thirtyDaysAgo: Date,
  ): Promise<AdminRawOverviewBundle> {
    const [
      reportGroups,
      siteGroups,
      duplicateGroupsCount,
      upcomingEvents,
      upcomingEventsList,
      pendingEvents,
      completedEvents,
      usersCount,
      usersNewLast7d,
      sessionsActive,
      reportCountsByDay,
      recentLogs,
      recentFeedDemotions,
      rankingCandidates,
      cleanupParticipantSum,
    ] = await Promise.all([
      this.prisma.report.groupBy({
        by: ['status'],
        orderBy: { status: 'asc' },
        _count: { _all: true },
      }),
      this.prisma.site.groupBy({
        by: ['status'],
        orderBy: { status: 'asc' },
        _count: { _all: true },
      }),
      this.prisma.report.count({
        where: {
          potentialDuplicateOfId: null,
          potentialDuplicates: { some: {} },
        },
      }),
      this.prisma.cleanupEvent.count({
        where: {
          completedAt: null,
          status: { in: ['PENDING', 'APPROVED'] },
        },
      }),
      this.prisma.cleanupEvent.findMany({
        where: {
          completedAt: null,
          status: { in: ['PENDING', 'APPROVED'] },
        },
        orderBy: { scheduledAt: 'asc' },
        take: 3,
        select: {
          id: true,
          scheduledAt: true,
          site: {
            select: { description: true, latitude: true, longitude: true },
          },
        },
      }),
      this.prisma.cleanupEvent.count({
        where: { status: 'PENDING' },
      }),
      this.prisma.cleanupEvent.count({
        where: {
          completedAt: {
            not: null,
          },
        },
      }),
      this.prisma.user.count(),
      this.prisma.user.count({
        where: { createdAt: { gte: sevenDaysAgo } },
      }),
      this.prisma.userSession.count({
        where: {
          revokedAt: null,
          expiresAt: { gt: now },
        },
      }),
      this.reportDailyCountsSince(thirtyDaysAgo),
      this.prisma.auditLog.findMany({
        orderBy: { createdAt: 'desc' },
        take: 10,
        include: {
          actor: { select: { email: true } },
        },
      }),
      this.prisma.auditLog.count({
        where: {
          action: { contains: 'INTEGRITY_DAMPENED' },
          createdAt: { gte: sevenDaysAgo },
        },
      }),
      this.prisma.site.findMany({
        where: { status: { in: ['REPORTED', 'VERIFIED', 'IN_PROGRESS', 'CLEANUP_SCHEDULED'] } },
        orderBy: { updatedAt: 'desc' },
        take: 40,
        include: {
          reports: {
            orderBy: { createdAt: 'desc' },
            take: 1,
            select: { createdAt: true, category: true, title: true },
          },
        },
      }),
      this.prisma.cleanupEvent.aggregate({
        _sum: { participantCount: true },
        where: {
          status: 'APPROVED',
          lifecycleStatus: { not: 'CANCELLED' },
        },
      }),
    ]);

    return {
      reportGroups,
      siteGroups,
      duplicateGroupsCount,
      upcomingEvents,
      upcomingEventsList,
      pendingEvents,
      completedEvents,
      usersCount,
      usersNewLast7d,
      sessionsActive,
      reportCountsByDay,
      recentLogs,
      recentFeedDemotions,
      rankingCandidates,
      cleanupParticipantSum,
    };
  }
}
