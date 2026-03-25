const MS_PER_SECOND = 1000;
const MS_PER_MINUTE = 60 * MS_PER_SECOND;
const MS_PER_HOUR = 60 * MS_PER_MINUTE;
const MS_PER_DAY = 24 * MS_PER_HOUR;

/**
 * Parses the first language tag from an Accept-Language header (e.g. "mk-MK,en;q=0.9" → "mk-MK").
 */
export function localeFromAcceptLanguage(acceptLanguage?: string): string {
  if (!acceptLanguage?.trim()) {
    return 'en';
  }
  const first = acceptLanguage.split(',')[0]?.trim().split(';')[0]?.trim();
  return first && first.length > 0 ? first : 'en';
}

/**
 * Human-readable relative time since `createdAt` (for notification lists).
 * Uses Intl.RelativeTimeFormat; treats times under one minute ago (and future skew) as "Just now".
 */
export function formatRelativeTimeSince(
  createdAt: Date,
  now: Date,
  locale: string,
): string {
  const diffMs = now.getTime() - createdAt.getTime();
  if (diffMs < MS_PER_MINUTE) {
    return 'Just now';
  }

  const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });

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
