import { ActiveUsersAdminService } from '../../src/active-users/services/active-users-admin.service';
import { ActiveUsersPresenceService } from '../../src/active-users/services/active-users-presence.service';
import { ActiveUsersRealtimeService } from '../../src/active-users/services/active-users-realtime.service';
import { UserActivityService } from '../../src/active-users/services/user-activity.service';

describe('ActiveUsersAdminService', () => {
  const presence = {
    countByStatus: jest.fn(),
    listActiveRows: jest.fn(),
    countDistinctActive: jest.fn(),
    getGeoClusters: jest.fn(),
  } as unknown as ActiveUsersPresenceService;

  const realtime = {
    getPeakToday: jest.fn().mockResolvedValue(3),
    getPeakWeek: jest.fn().mockResolvedValue(5),
    getTrend: jest.fn().mockResolvedValue([1, 2, 3]),
    getAvgConcurrent: jest.fn().mockResolvedValue(2.5),
  } as unknown as ActiveUsersRealtimeService;

  const activity = {} as UserActivityService;

  function createService(prisma: Record<string, unknown>) {
    return new ActiveUsersAdminService(presence, realtime, activity, prisma as never);
  }

  it('computes engagement analytics from Postgres activity events', async () => {
    const queryRaw = jest
      .fn()
      .mockResolvedValueOnce([{ count: 4n }])
      .mockResolvedValueOnce([{ count: 9n }])
      .mockResolvedValueOnce([{ count: 20n }])
      .mockResolvedValueOnce([
        { date: '2026-06-07', dau: 3n },
        { date: '2026-06-08', dau: 4n },
      ])
      .mockResolvedValueOnce([{ avg_minutes: 12.5 }]);

    const prisma = {
      $queryRaw: queryRaw,
      userActivityEvent: {
        count: jest
          .fn()
          .mockResolvedValueOnce(8)
          .mockResolvedValueOnce(2),
      },
      dailyActiveStat: {
        findMany: jest.fn().mockResolvedValue([
          {
            date: new Date('2026-06-07T00:00:00.000Z'),
            dau: 3,
            wau: 10,
            mau: 25,
            peakConcurrent: 6,
            avgConcurrent: 2.2,
          },
        ]),
      },
    };

    const service = createService(prisma);
    const result = await service.getEngagementAnalytics();

    expect(result.dau).toBe(4);
    expect(result.wau).toBe(9);
    expect(result.mau).toBe(20);
    expect(result.sessionsPerUser).toBe(2);
    expect(result.reportsSubmittedToday).toBe(2);
    expect(result.avgSessionDurationMinutes).toBe(12.5);
    expect(result.history).toHaveLength(30);
    expect(result.history.find((row) => row.date === '2026-06-07')).toEqual(
      expect.objectContaining({
        dau: 3,
        wau: 10,
        mau: 25,
        peakConcurrent: 6,
        avgConcurrent: 2.2,
      }),
    );
    expect(result.history.some((row) => row.dau === 4)).toBe(true);
  });
});
