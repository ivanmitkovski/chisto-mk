const MS_PER_SECOND = 1000;
const MS_PER_MINUTE = 60 * MS_PER_SECOND;
const MS_PER_HOUR = 60 * MS_PER_MINUTE;
const MS_PER_DAY = 24 * MS_PER_HOUR;

/**
 * Relative time for admin notification rows (mirrors API `formatRelativeTimeSince` logic).
 * Prefer `createdAt` ISO from the API; `fallbackLabel` is used when missing (older APIs) or invalid date.
 */
export function formatNotificationRelativeTimeFromIso(
  createdAtIso: string | undefined,
  fallbackLabel: string,
  locale?: string,
): string {
  if (!createdAtIso?.trim()) {
    return fallbackLabel;
  }
  const created = new Date(createdAtIso);
  if (Number.isNaN(created.getTime())) {
    return fallbackLabel;
  }

  const nowMs = Date.now();
  const diffMs = nowMs - created.getTime();
  const effectiveLocale =
    locale?.trim() ||
    (typeof navigator !== 'undefined' ? navigator.language : undefined) ||
    'en';

  const rtf = new Intl.RelativeTimeFormat(effectiveLocale, { numeric: 'auto' });

  if (diffMs < 0) {
    return 'Just now';
  }

  if (diffMs < 10 * MS_PER_SECOND) {
    return 'Just now';
  }

  if (diffMs < MS_PER_MINUTE) {
    const seconds = Math.floor(diffMs / MS_PER_SECOND);
    return rtf.format(-seconds, 'second');
  }

  if (diffMs < MS_PER_HOUR) {
    const minutes = Math.floor(diffMs / MS_PER_MINUTE);
    return rtf.format(-minutes, 'minute');
  }

  if (diffMs < MS_PER_DAY) {
    const hours = Math.floor(diffMs / MS_PER_HOUR);
    return rtf.format(-hours, 'hour');
  }

  const days = Math.floor(diffMs / MS_PER_DAY);
  if (days < 7) {
    return rtf.format(-days, 'day');
  }

  const weeks = Math.floor(days / 7);
  if (weeks < 5) {
    return rtf.format(-weeks, 'week');
  }

  const months = Math.floor(days / 30);
  if (months < 12) {
    return rtf.format(-months, 'month');
  }

  const years = Math.floor(days / 365);
  return rtf.format(-years, 'year');
}
