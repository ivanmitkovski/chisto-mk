/// <reference types="jest" />

import { AdminAggregationQueryService } from '../../src/admin/admin-aggregation-query.service';
import type { AdminRawOverviewBundle } from '../../src/admin/admin-dashboard-stats.service';

import { FeedRankingService } from '../../src/sites/feed-ranking.service';

describe('AdminAggregationQueryService', () => {
  const scoreDetailed = jest.fn().mockReturnValue({
    score: 1,
    reasonCodes: ['recency'],
    components: {},
  });
  const feedRanking = { scoreDetailed } as unknown as FeedRankingService;

  const emptyBundle = (): AdminRawOverviewBundle => ({
    reportGroups: [{ status: 'NEW', _count: { _all: 2 } }],
    siteGroups: [{ status: 'REPORTED', _count: { _all: 1 } }],
    duplicateGroupsCount: 0,
    upcomingEvents: 0,
    upcomingEventsList: [],
    pendingEvents: 1,
    completedEvents: 4,
    usersCount: 10,
    usersNewLast7d: 1,
    sessionsActive: 2,
    reportCountsByDay: [{ date: '2026-01-01', count: 5n }],
    recentLogs: [],
    recentFeedDemotions: 0,
    rankingCandidates: [],
    cleanupParticipantSum: { _sum: { participantCount: 7 } },
  });

  it('assembleOverviewStats aggregates reports and sites by status', () => {
    const svc = new AdminAggregationQueryService(feedRanking);
    const stats = svc.assembleOverviewStats(emptyBundle());
    expect(stats.reportsByStatus.NEW).toBe(2);
    expect(stats.sitesByStatus.REPORTED).toBe(1);
    expect(stats.cleanupEvents.totalParticipants).toBe(7);
    expect(stats.reportsTrend[0]!.count).toBe(5);
    expect(scoreDetailed).not.toHaveBeenCalled();
  });

  it('assembleOverviewStats calls scoreDetailed for ranking candidates', () => {
    const svc = new AdminAggregationQueryService(feedRanking);
    const raw = emptyBundle();
    raw.rankingCandidates = [
      {
        id: 'site-1',
        createdAt: new Date('2026-01-01T00:00:00.000Z'),
        updatedAt: new Date('2026-01-01T00:00:00.000Z'),
        status: 'VERIFIED',
        upvotesCount: 1,
        commentsCount: 0,
        savesCount: 0,
        sharesCount: 0,
        reports: [{ createdAt: new Date('2026-01-02T00:00:00.000Z'), category: 'illegal_dump', title: 'T' }],
      },
    ];
    svc.assembleOverviewStats(raw);
    expect(scoreDetailed).toHaveBeenCalled();
  });
});
