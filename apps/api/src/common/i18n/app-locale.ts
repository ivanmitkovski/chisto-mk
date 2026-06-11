/**
 * Supported mobile app UI locales (aligned with ARB catalogs and error i18n).
 */
export type AppLocale = 'en' | 'mk' | 'sq';

export const DEFAULT_APP_LOCALE: AppLocale = 'mk';

const APP_LOCALE_SET = new Set<string>(['en', 'mk', 'sq']);

/**
 * Normalizes a raw locale string (device token, user profile, Accept-Language fragment).
 */
export function normalizeAppLocale(raw: string | null | undefined): AppLocale {
  const s = raw?.trim().toLowerCase() ?? '';
  if (s.startsWith('sq')) {
    return 'sq';
  }
  if (s.startsWith('en')) {
    return 'en';
  }
  if (s.startsWith('mk')) {
    return 'mk';
  }
  return DEFAULT_APP_LOCALE;
}

export function isAppLocale(raw: string | null | undefined): raw is AppLocale {
  return raw != null && APP_LOCALE_SET.has(raw.trim().toLowerCase());
}
