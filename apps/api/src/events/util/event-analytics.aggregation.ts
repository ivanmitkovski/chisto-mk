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
  /** ISO-8601 instant when this payload was built (for client “updated” UI). */
  generatedAt: string;
  /** ISO-8601 instant of the most recent participant join, if any. */
  lastJoinAt: string | null;
  /** ISO-8601 instant of the most recent check-in, if any. */
  lastCheckInAt: string | null;
};

export type BuildEventAnalyticsInput = {
  participantCount: number;
  participantsJoinedAt: Date[];
  checkInsCheckedAt: Date[];
  /** When set, skips scanning [checkInsCheckedAt] for counts/hourly (used for DB-aggregated paths). */
  checkedInCountOverride?: number;
  /** When set with [checkedInCountOverride], skips deriving hourly buckets from [checkInsCheckedAt]. */
  checkInsByHourOverride?: CheckInsByHourPoint[];
};

export function buildEventAnalyticsPayload(input: BuildEventAnalyticsInput): EventAnalyticsPayload {
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

  let checkInsByHour: CheckInsByHourPoint[];
  if (input.checkInsByHourOverride != null) {
    checkInsByHour = input.checkInsByHourOverride;
  } else {
    // UTC bucketing (deterministic across deploy regions). Event-local TZ can map from scheduledAt later.
    const hourCounts = Array.from({ length: 24 }, () => 0);
    for (const checkedInAt of input.checkInsCheckedAt) {
      const hour = checkedInAt.getUTCHours();
      hourCounts[hour] += 1;
    }
    checkInsByHour = hourCounts.map((count, hour) => ({ hour, count }));
  }

  const checkedInCount = input.checkedInCountOverride ?? input.checkInsCheckedAt.length;
  const attendanceRate =
    totalJoiners > 0 ? Math.round((checkedInCount / Math.max(totalJoiners, 1)) * 100) : 0;

  const sortedCheckIns = [...input.checkInsCheckedAt].sort((a, b) => a.getTime() - b.getTime());
  const lastJoinAt =
    sortedJoins.length > 0 ? sortedJoins[sortedJoins.length - 1]!.toISOString() : null;
  const lastCheckInAt =
    sortedCheckIns.length > 0 ? sortedCheckIns[sortedCheckIns.length - 1]!.toISOString() : null;

  return {
    totalJoiners,
    checkedInCount,
    attendanceRate,
    joinersCumulative,
    checkInsByHour,
    generatedAt: new Date().toISOString(),
    lastJoinAt,
    lastCheckInAt,
  };
}
