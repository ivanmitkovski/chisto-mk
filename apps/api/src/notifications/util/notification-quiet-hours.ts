import { DateTime } from 'luxon';

export type QuietHoursPrefs = {
  quietHoursStart: number | null;
  quietHoursEnd: number | null;
  quietHoursTimezone: string | null;
};

/** Returns delay until quiet window ends, or null if push may send now. */
export function computeQuietHoursDeferral(
  prefs: QuietHoursPrefs,
  interruptionLevel: 'time-sensitive' | 'active' | 'passive',
): Date | null {
  if (interruptionLevel === 'time-sensitive') {
    return null;
  }
  const start = prefs.quietHoursStart;
  const end = prefs.quietHoursEnd;
  if (start == null || end == null) {
    return null;
  }
  const zone = prefs.quietHoursTimezone?.trim() || 'UTC';
  const now = DateTime.now().setZone(zone);
  const startToday = now.startOf('day').plus({ minutes: start });
  const endToday = now.startOf('day').plus({ minutes: end });

  const inWindow =
    start < end
      ? now >= startToday && now < endToday
      : now >= startToday || now < endToday;

  if (!inWindow) {
    return null;
  }

  const resumeAt = start < end ? endToday : now < endToday ? endToday : endToday.plus({ days: 1 });
  return resumeAt.toUTC().toJSDate();
}
