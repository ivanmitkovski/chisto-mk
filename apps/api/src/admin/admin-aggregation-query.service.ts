import { Injectable } from '@nestjs/common';
import { FeedRankingService } from '../sites/feed-ranking.service';
import type { AdminOverviewStats } from './admin-overview.types';
import type { AdminRawOverviewBundle } from './admin-dashboard-stats.service';

@Injectable()
export class AdminAggregationQueryService {
  constructor(private readonly feedRanking: FeedRankingService) {}

  assembleOverviewStats(raw: AdminRawOverviewBundle): AdminOverviewStats {
    const reportsByStatus: Record<string, number> = {};
    for (const group of raw.reportGroups) {
      const countAll =
        typeof group._count === 'object' &&
        group._count &&
        '_all' in group._count &&
        typeof group._count._all === 'number'
          ? group._count._all
          : 0;
      reportsByStatus[group.status] = countAll;
    }

    const sitesByStatus: Record<string, number> = {};
    for (const group of raw.siteGroups) {
      const countAll =
        typeof group._count === 'object' &&
        group._count &&
        '_all' in group._count &&
        typeof group._count._all === 'number'
          ? group._count._all
          : 0;
      sitesByStatus[group.status] = countAll;
    }

    const reportsTrend = raw.reportCountsByDay.map((r) => ({
      date: r.date,
      count: Number(r.count),
    }));

    const recentActivity = raw.recentLogs.map((log) => ({
      id: log.id,
      createdAt: log.createdAt.toISOString(),
      action: log.action,
      resourceType: log.resourceType,
      resourceId: log.resourceId,
      actorEmail: log.actor?.email ?? null,
    }));

    const upcomingEventsFormatted = raw.upcomingEventsList.map((e) => {
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
    const rankDriftSnapshot = raw.rankingCandidates.slice(0, 8).map((site) => {
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
      duplicateGroupsCount: raw.duplicateGroupsCount,
      cleanupEvents: {
        upcoming: raw.upcomingEvents,
        completed: raw.completedEvents,
        pending: raw.pendingEvents,
        totalParticipants: Number(raw.cleanupParticipantSum._sum.participantCount ?? 0),
        upcomingEvents: upcomingEventsFormatted,
      },
      usersCount: raw.usersCount,
      usersNewLast7d: raw.usersNewLast7d,
      sessionsActive: raw.sessionsActive,
      reportsTrend,
      recentActivity,
      feedDiagnostics: {
        reasonCodes,
        rankDriftSnapshot,
        recentIntegrityDemotions: raw.recentFeedDemotions,
      },
    };
  }
}
