const MS_PER_SECOND = 1000;
const MS_PER_MINUTE = 60 * MS_PER_SECOND;
const MS_PER_HOUR = 60 * MS_PER_MINUTE;
const MS_PER_DAY = 24 * MS_PER_HOUR;
const DEFAULT_LOCALE = 'en';

/** BCP 47 primary tag (e.g. en, mk-MK). Rejects wildcards like `*` from fetch defaults. */
const LOCALE_TAG_PATTERN = /^[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*$/;

function isUsableLanguageTag(tag: string): boolean {
  return tag.length > 0 && tag !== '*' && LOCALE_TAG_PATTERN.test(tag);
}

/**
 * Parses the first language tag from an Accept-Language header (e.g. "mk-MK,en;q=0.9" → "mk-MK").
 */
export function localeFromAcceptLanguage(acceptLanguage?: string): string {
  if (!acceptLanguage?.trim()) {
    return DEFAULT_LOCALE;
  }
  const first = acceptLanguage.split(',')[0]?.trim().split(';')[0]?.trim();
  return first && isUsableLanguageTag(first) ? first : DEFAULT_LOCALE;
}

function resolveSupportedLocale(locale: string): string {
  const normalized = locale.replace(/_/g, '-').trim();
  if (!isUsableLanguageTag(normalized)) {
    return DEFAULT_LOCALE;
  }

  try {
    // Prefer exact locale; fallback to language-only; then default.
    const exact = Intl.RelativeTimeFormat.supportedLocalesOf([normalized]);
    if (exact.length > 0) {
      return exact[0];
    }

    const languageOnly = normalized.split('-')[0] ?? '';
    if (!isUsableLanguageTag(languageOnly)) {
      return DEFAULT_LOCALE;
    }
    const language = Intl.RelativeTimeFormat.supportedLocalesOf([languageOnly]);
    if (language.length > 0) {
      return language[0];
    }
  } catch {
    return DEFAULT_LOCALE;
  }

  return DEFAULT_LOCALE;
}

function createRelativeTimeFormatter(locale: string): Intl.RelativeTimeFormat {
  const safeLocale = resolveSupportedLocale(locale);
  try {
    return new Intl.RelativeTimeFormat(safeLocale, { numeric: 'auto' });
  } catch {
    // Safety net for environments with partial ICU data.
    return new Intl.RelativeTimeFormat(DEFAULT_LOCALE, { numeric: 'auto' });
  }
}

/**
 * Human-readable relative time since `createdAt` (for notification lists).
 * Uses Intl.RelativeTimeFormat; under ~10s and future skew → "Just now"; 10s–59s → seconds ago.
 */
export function formatRelativeTimeSince(
  createdAt: Date,
  now: Date,
  locale: string,
): string {
  const diffMs = now.getTime() - createdAt.getTime();
  const rtf = createRelativeTimeFormatter(locale);

  if (diffMs < 0 || diffMs < 10 * MS_PER_SECOND) {
    return rtf.format(0, 'second');
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
