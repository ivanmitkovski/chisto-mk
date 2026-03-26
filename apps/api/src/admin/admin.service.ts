import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import { SessionsService } from '../sessions/sessions.service';
import { FeedRankingService } from '../sites/feed-ranking.service';

export type AdminOverviewStats = {
  reportsByStatus: Record<string, number>;
  sitesByStatus: Record<string, number>;
  duplicateGroupsCount: number;
  cleanupEvents: {
    upcoming: number;
    completed: number;
    pending: number;
    upcomingEvents: Array<{ id: string; name: string; date: string }>;
  };
  usersCount: number;
  usersNewLast7d: number;
  sessionsActive: number;
  reportsTrend: Array<{ date: string; count: number }>;
  recentActivity: Array<{
    id: string;
    createdAt: string;
    action: string;
    resourceType: string;
    resourceId: string | null;
    actorEmail: string | null;
  }>;
  feedDiagnostics: {
    reasonCodes: Array<{ code: string; count: number }>;
    rankDriftSnapshot: Array<{ siteId: string; score: number; reasons: string[] }>;
    recentIntegrityDemotions: number;
  };
};

export type AdminSecuritySession = {
  id: string;
  device: string;
  location: string;
  ipAddress: string;
  lastActiveLabel: string;
  isCurrent: boolean;
};

export type AdminSecurityActivityTone = 'success' | 'warning' | 'info';

export type AdminSecurityActivityEvent = {
  id: string;
  title: string;
  detail: string;
  occurredAtLabel: string;
  tone: AdminSecurityActivityTone;
  icon: string;
};

export type AdminSecurityOverview = {
  sessions: AdminSecuritySession[];
  activity: AdminSecurityActivityEvent[];
};

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly sessions: SessionsService,
    private readonly feedRanking: FeedRankingService,
  ) {}

  async getOverview(): Promise<AdminOverviewStats> {
    const now = new Date();
    const sevenDaysAgo = new Date(now);
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const thirtyDaysAgo = new Date(now);
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

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
    ] = await this.prisma.$transaction([
      this.prisma.report.groupBy({
        by: ['status'],
        orderBy: {
          status: 'asc',
        },
        _count: { _all: true },
      }),
      this.prisma.site.groupBy({
        by: ['status'],
        orderBy: {
          status: 'asc',
        },
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
      this.prisma.$queryRaw<Array<{ date: string; count: bigint }>>`
        SELECT ("createdAt"::date)::text as date, COUNT(*)::bigint as count
        FROM "Report"
        WHERE "createdAt" >= ${thirtyDaysAgo}
        GROUP BY "createdAt"::date
        ORDER BY date ASC
      `,
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
    ]);

    const reportsByStatus: Record<string, number> = {};
    for (const group of reportGroups) {
      const countAll =
        typeof group._count === 'object' && group._count && '_all' in group._count && typeof group._count._all === 'number'
          ? group._count._all
          : 0;
      reportsByStatus[group.status] = countAll;
    }

    const sitesByStatus: Record<string, number> = {};
    for (const group of siteGroups) {
      const countAll =
        typeof group._count === 'object' && group._count && '_all' in group._count && typeof group._count._all === 'number'
          ? group._count._all
          : 0;
      sitesByStatus[group.status] = countAll;
    }

    const reportsTrend = reportCountsByDay.map((r) => ({
      date: r.date,
      count: Number(r.count),
    }));

    const recentActivity = recentLogs.map((log) => ({
      id: log.id,
      createdAt: log.createdAt.toISOString(),
      action: log.action,
      resourceType: log.resourceType,
      resourceId: log.resourceId,
      actorEmail: log.actor?.email ?? null,
    }));

    const upcomingEventsFormatted = upcomingEventsList.map((e) => {
      const name =
        e.site.description?.trim() ||
        `Cleanup at ${e.site.latitude.toFixed(2)}, ${e.site.longitude.toFixed(2)}`;
      return {
        id: e.id,
        name,
        date: e.scheduledAt.toISOString(),
      };
    });

    const reasonCodeCounts = new Map<string, number>();
    const rankDriftSnapshot = rankingCandidates.slice(0, 8).map((site) => {
      const report = site.reports[0];
      const detail = this.feedRanking.scoreDetailed({
        siteId: site.id,
        createdAt: report?.createdAt ?? site.createdAt,
        upvotesCount: site.upvotesCount,
        commentsCount: site.commentsCount,
        savesCount: site.savesCount,
        sharesCount: site.sharesCount,
        status: site.status,
        reportCount: report ? 1 : 0,
        sessionCategoryAffinity: report?.category ? 0.5 : 0,
        policyEligibility: site.status === 'DISPUTED' ? 0.35 : 1,
      });
      for (const reason of detail.reasonCodes) {
        reasonCodeCounts.set(reason, (reasonCodeCounts.get(reason) ?? 0) + 1);
      }
      return {
        siteId: site.id,
        score: Number(detail.score.toFixed(4)),
        reasons: detail.reasonCodes,
      };
    });
    const reasonCodes = [...reasonCodeCounts.entries()]
      .map(([code, count]) => ({ code, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 8);

    return {
      reportsByStatus,
      sitesByStatus,
      duplicateGroupsCount,
      cleanupEvents: {
        upcoming: upcomingEvents,
        completed: completedEvents,
        pending: pendingEvents,
        upcomingEvents: upcomingEventsFormatted,
      },
      usersCount,
      usersNewLast7d,
      sessionsActive,
      reportsTrend,
      recentActivity,
      feedDiagnostics: {
        reasonCodes,
        rankDriftSnapshot,
        recentIntegrityDemotions: recentFeedDemotions,
      },
    };
  }

  async getSecurityOverview(admin: AuthenticatedUser): Promise<AdminSecurityOverview> {
    const sessions = await this.sessions.listMine(admin);
    const activity = await this.audit.recentForUser(admin.userId, 20);
    return {
      sessions,
      activity,
    };
  }
}

