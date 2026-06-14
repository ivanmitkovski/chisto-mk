import { ADMIN_DISPLAY_TIME_ZONE } from '@/lib/i18n/format-admin-datetime';
import { ADMIN_LOCALE_BCP47, normalizeLocale } from '@/lib/preferences/admin-locale';

/** North Macedonia schedule display for admin; fixed TZ avoids SSR/client hydration mismatches. */
export const EVENT_ADMIN_TZ = ADMIN_DISPLAY_TIME_ZONE;

export function toAdminBcp47Locale(locale: string): string {
  return ADMIN_LOCALE_BCP47[normalizeLocale(locale)];
}

export function formatEventAdminDateTime(iso: string, locale: string = ADMIN_LOCALE_BCP47.en): string {
  return new Date(iso).toLocaleString(toAdminBcp47Locale(locale), {
    timeZone: EVENT_ADMIN_TZ,
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

/** `datetime-local` value in [EVENT_ADMIN_TZ] wall time (stable across Node SSR and browsers). */
export function toDatetimeLocalField(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) {
    return '';
  }
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: EVENT_ADMIN_TZ,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(d);
  const v = (t: Intl.DateTimeFormatPartTypes) => parts.find((p) => p.type === t)?.value ?? '00';
  return `${v('year')}-${v('month')}-${v('day')}T${v('hour')}:${v('minute')}`;
}

/** `datetime-local` default for create forms in [EVENT_ADMIN_TZ] wall time. */
export function toDatetimeLocalFromDate(date: Date): string {
  return toDatetimeLocalField(date.toISOString());
}

/** Default end ISO = scheduled start + 3 hours. */
export function defaultEndAtIsoFromScheduled(scheduledAtIso: string): string {
  const next = new Date(scheduledAtIso);
  next.setTime(next.getTime() + 3 * 60 * 60 * 1000);
  return next.toISOString();
}

/** Default create-form start: one week ahead at 10:00 in admin TZ. */
export function defaultCreateScheduledAtLocal(): string {
  const d = new Date();
  d.setDate(d.getDate() + 7);
  d.setHours(10, 0, 0, 0);
  return toDatetimeLocalFromDate(d);
}
