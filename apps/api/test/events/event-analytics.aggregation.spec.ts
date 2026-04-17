import { buildEventAnalyticsPayload } from '../../src/events/event-analytics.aggregation';

describe('buildEventAnalyticsPayload', () => {
  it('returns 24 hourly buckets in UTC with zero defaults', () => {
    const out = buildEventAnalyticsPayload({
      participantCount: 0,
      participantsJoinedAt: [],
      checkInsCheckedAt: [],
    });
    expect(out.checkInsByHour).toHaveLength(24);
    expect(out.checkInsByHour.map((h) => h.hour)).toEqual(
      Array.from({ length: 24 }, (_, i) => i),
    );
    expect(out.checkInsByHour.every((h) => h.count === 0)).toBe(true);
    expect(out.joinersCumulative).toEqual([]);
    expect(out.checkedInCount).toBe(0);
    expect(out.attendanceRate).toBe(0);
  });

  it('emits one cumulative point per join in time order', () => {
    const out = buildEventAnalyticsPayload({
      participantCount: 3,
      participantsJoinedAt: [
        new Date('2026-01-02T12:00:00.000Z'),
        new Date('2026-01-01T12:00:00.000Z'),
      ],
      checkInsCheckedAt: [],
    });
    expect(out.joinersCumulative).toHaveLength(2);
    expect(out.joinersCumulative[0].at).toBe('2026-01-01T12:00:00.000Z');
    expect(out.joinersCumulative[0].cumulativeJoiners).toBe(1);
    expect(out.joinersCumulative[1].cumulativeJoiners).toBe(2);
    expect(out.totalJoiners).toBe(3);
    expect(out.checkedInCount).toBe(0);
    expect(out.attendanceRate).toBe(0);
  });

  it('buckets check-ins by UTC hour and matches checkedInCount', () => {
    const out = buildEventAnalyticsPayload({
      participantCount: 4,
      participantsJoinedAt: [],
      checkInsCheckedAt: [
        new Date('2026-06-01T11:15:00.000Z'),
        new Date('2026-06-01T11:45:00.000Z'),
        new Date('2026-06-02T23:01:00.000Z'),
      ],
    });
    expect(out.checkedInCount).toBe(3);
    expect(out.checkInsByHour[11].count).toBe(2);
    expect(out.checkInsByHour[23].count).toBe(1);
    expect(out.checkInsByHour.reduce((s, h) => s + h.count, 0)).toBe(3);
    expect(out.attendanceRate).toBe(75);
  });
});
