import type { EmailLocale } from '../types/email.types';

const TIME_ZONE = 'Europe/Skopje';

function localeTag(locale: EmailLocale): string {
  return locale === 'en' ? 'en-GB' : 'mk-MK';
}

function parseDate(value: unknown): Date | null {
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return value;
  }
  if (typeof value === 'string' && value.trim()) {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  return null;
}

export function formatDateTime(locale: EmailLocale, value: unknown): string {
  const date = parseDate(value);
  if (!date) return '';
  return new Intl.DateTimeFormat(localeTag(locale), {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: TIME_ZONE,
  }).format(date);
}

export function formatDateRange(
  locale: EmailLocale,
  startValue: unknown,
  endValue?: unknown,
): string {
  const start = parseDate(startValue);
  if (!start) return '';
  const end = endValue != null ? parseDate(endValue) : null;
  if (!end) {
    return formatDateTime(locale, start);
  }

  const dateFmt = new Intl.DateTimeFormat(localeTag(locale), {
    dateStyle: 'medium',
    timeZone: TIME_ZONE,
  });
  const timeFmt = new Intl.DateTimeFormat(localeTag(locale), {
    timeStyle: 'short',
    timeZone: TIME_ZONE,
  });

  const startDate = dateFmt.format(start);
  const endDate = dateFmt.format(end);
  if (startDate === endDate) {
    return `${startDate}, ${timeFmt.format(start)}–${timeFmt.format(end)}`;
  }
  return `${formatDateTime(locale, start)} – ${formatDateTime(locale, end)}`;
}
