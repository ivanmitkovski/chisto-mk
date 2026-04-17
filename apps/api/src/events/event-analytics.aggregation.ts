/**
 * Pure aggregation for `GET .../analytics` (organizer + admin). Single source of truth
 * to avoid drift between {@link EventsService} and {@link CleanupEventsService}.
 *
 * Check-in hour buckets use **UTC** (see inline note for future event-local TZ).
 */
export type JoinersCumulativePoint = {
  /** ISO-8601 instant when the participant row was created (join moment). */
  at: string;
  cumulativeJoiners: number;
};

export type CheckInsByHourPoint = {
  hour: number;
  count: number;
};

export type EventAnalyticsPayload = {
  totalJoiners: number;
  checkedInCount: number;
  attendanceRate: number;
  joinersCumulative: JoinersCumulativePoint[];
  checkInsByHour: CheckInsByHourPoint[];
};

export function buildEventAnalyticsPayload(input: {
  participantCount: number;
  participantsJoinedAt: Date[];
  checkInsCheckedAt: Date[];
}): EventAnalyticsPayload {
  const totalJoiners = input.participantCount;
  const sortedJoins = [...input.participantsJoinedAt].sort((a, b) => a.getTime() - b.getTime());

  let running = 0;
  const joinersCumulative: JoinersCumulativePoint[] = sortedJoins.map((joinedAt) => {
    running += 1;
    return {
      at: joinedAt.toISOString(),
      cumulativeJoiners: running,
    };
  });

  // UTC bucketing (deterministic across deploy regions). Event-local TZ can map from scheduledAt later.
  const hourCounts = Array.from({ length: 24 }, () => 0);
  for (const checkedInAt of input.checkInsCheckedAt) {
    const hour = checkedInAt.getUTCHours();
    hourCounts[hour] += 1;
  }
  const checkInsByHour: CheckInsByHourPoint[] = hourCounts.map((count, hour) => ({ hour, count }));

  const checkedInCount = input.checkInsCheckedAt.length;
  const attendanceRate =
    totalJoiners > 0 ? Math.round((checkedInCount / Math.max(totalJoiners, 1)) * 100) : 0;

  return {
    totalJoiners,
    checkedInCount,
    attendanceRate,
    joinersCumulative,
    checkInsByHour,
  };
}
