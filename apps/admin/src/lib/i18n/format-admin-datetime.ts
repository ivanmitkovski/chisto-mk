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
