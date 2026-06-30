import { ADMIN_LOCALE_BCP47, normalizeLocale, type AdminLocale } from '@/lib/preferences/admin-locale';

/** Fixed TZ for admin UI — keeps Node SSR and browser hydration aligned. */
export const ADMIN_DISPLAY_TIME_ZONE = 'Europe/Skopje';

const DEFAULT_OPTIONS: Intl.DateTimeFormatOptions = {
  dateStyle: 'medium',
  timeStyle: 'short',
  timeZone: ADMIN_DISPLAY_TIME_ZONE,
};

const GRANULAR_DATE_TIME_KEYS = [
  'weekday',
  'era',
  'year',
  'month',
  'day',
  'hour',
  'minute',
  'second',
  'fractionalSecondDigits',
  'timeZoneName',
  'hourCycle',
  'hour12',
] as const satisfies ReadonlyArray<keyof Intl.DateTimeFormatOptions>;

function hasGranularDateTimeOptions(options: Intl.DateTimeFormatOptions): boolean {
  return GRANULAR_DATE_TIME_KEYS.some((key) => options[key] != null);
}

function mergeDateTimeFormatOptions(
  overrides?: Intl.DateTimeFormatOptions,
): Intl.DateTimeFormatOptions {
  if (!overrides) {
    return DEFAULT_OPTIONS;
  }
  if (hasGranularDateTimeOptions(overrides)) {
    return { timeZone: ADMIN_DISPLAY_TIME_ZONE, ...overrides };
  }
  return { ...DEFAULT_OPTIONS, ...overrides };
}

function mergeDateFormatOptions(overrides?: Intl.DateTimeFormatOptions): Intl.DateTimeFormatOptions {
  if (!overrides) {
    return { dateStyle: 'medium', timeZone: ADMIN_DISPLAY_TIME_ZONE };
  }
  if (hasGranularDateTimeOptions(overrides)) {
    return { timeZone: ADMIN_DISPLAY_TIME_ZONE, ...overrides };
  }
  return { dateStyle: 'medium', timeZone: ADMIN_DISPLAY_TIME_ZONE, ...overrides };
}

function resolveBcp47(locale: string | AdminLocale): string {
  if (locale.includes('-')) {
    return locale;
  }
  return ADMIN_LOCALE_BCP47[normalizeLocale(locale)];
}

export type AdminActivityDayLabels = {
  today: string;
  yesterday: string;
};

/** Calendar day (YYYY-MM-DD) in the admin display timezone — stable for grouping and comparisons. */
export function adminCalendarDayKey(iso: string | Date, timeZone = ADMIN_DISPLAY_TIME_ZONE): string {
  const date = iso instanceof Date ? iso : new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return '';
  }
  return new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
}

/**
 * Contextual timestamp for live activity feeds: "Today · 14:32", "Yesterday · 09:05", "28 Jun · 14:32".
 * Uses the admin display timezone so list rows match operator expectations in North Macedonia.
 */
export function formatAdminActivityTimestamp(
  iso: string | Date,
  locale: string | AdminLocale,
  labels: AdminActivityDayLabels,
  now: Date = new Date(),
): string {
  const date = iso instanceof Date ? iso : new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return '—';
  }

  const bcp47 = resolveBcp47(locale);
  const time = date.toLocaleString(bcp47, {
    timeZone: ADMIN_DISPLAY_TIME_ZONE,
    hour: '2-digit',
    minute: '2-digit',
  });

  const eventDay = adminCalendarDayKey(date);
  const todayDay = adminCalendarDayKey(now);
  if (!eventDay) return '—';

  if (eventDay === todayDay) {
    return `${labels.today} · ${time}`;
  }

  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  if (eventDay === adminCalendarDayKey(yesterday)) {
    return `${labels.yesterday} · ${time}`;
  }

  const eventYear = eventDay.slice(0, 4);
  const todayYear = todayDay.slice(0, 4);
  const dateLabel = date.toLocaleString(bcp47, {
    timeZone: ADMIN_DISPLAY_TIME_ZONE,
    ...(eventYear === todayYear
      ? { month: 'short', day: 'numeric' }
      : { month: 'short', day: 'numeric', year: 'numeric' }),
  });

  return `${dateLabel} · ${time}`;
}

/** Locale-aware date/time formatting for admin tables and detail views. */
export function formatAdminDateTime(
  iso: string | Date,
  locale: string | AdminLocale,
  options?: Intl.DateTimeFormatOptions,
): string {
  const date = iso instanceof Date ? iso : new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return '—';
  }
  return date.toLocaleString(resolveBcp47(locale), mergeDateTimeFormatOptions(options));
}

/** Date-only variant (no time). */
export function formatAdminDate(
  iso: string | Date,
  locale: string | AdminLocale,
  options?: Intl.DateTimeFormatOptions,
): string {
  const date = iso instanceof Date ? iso : new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return '—';
  }
  return date.toLocaleDateString(resolveBcp47(locale), mergeDateFormatOptions(options));
}
