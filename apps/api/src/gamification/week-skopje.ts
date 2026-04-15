import { DateTime } from 'luxon';

/** IANA timezone for weekly boundaries (Monday 00:00 → Sunday end of day, ISO week). */
export const SKOPJE_TZ = 'Europe/Skopje';

export interface SkopjeWeekBoundsUtc {
  /** Inclusive lower bound in UTC (Monday 00:00 Skopje). */
  weekStartsAt: Date;
  /** Inclusive upper bound in UTC (Sunday 23:59:59.999 Skopje). */
  weekEndsAt: Date;
  weekStartsAtIso: string;
  weekEndsAtIso: string;
}

/**
 * Current calendar week in Skopje: Monday start of day through Sunday end of day.
 * Matches ISO weekday numbering (Luxon: Monday = 1 … Sunday = 7).
 */
export function getSkopjeWeekBoundsUtc(now: Date = new Date()): SkopjeWeekBoundsUtc {
  const z = DateTime.fromJSDate(now, { zone: 'utc' }).setZone(SKOPJE_TZ);
  const mondayLocal = z.minus({ days: z.weekday - 1 }).startOf('day');
  const sundayEndLocal = mondayLocal.plus({ days: 6 }).endOf('day');
  const weekStartsAt = mondayLocal.toUTC().toJSDate();
  const weekEndsAt = sundayEndLocal.toUTC().toJSDate();
  return {
    weekStartsAt,
    weekEndsAt,
    weekStartsAtIso: weekStartsAt.toISOString(),
    weekEndsAtIso: weekEndsAt.toISOString(),
  };
}
