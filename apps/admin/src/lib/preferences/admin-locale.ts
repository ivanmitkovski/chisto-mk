export const ADMIN_LOCALE_COOKIE = 'chisto.admin.ui.locale';
export const ADMIN_LOCALE_STORAGE_KEY = ADMIN_LOCALE_COOKIE;

export const ADMIN_LOCALES = ['en', 'mk', 'sq'] as const;
export type AdminLocale = (typeof ADMIN_LOCALES)[number];

export const DEFAULT_ADMIN_LOCALE: AdminLocale = 'en';

export const ADMIN_LOCALE_DISPLAY_NAMES: Record<AdminLocale, string> = {
  en: 'English',
  mk: 'Македонски',
  sq: 'Shqip',
};

/** BCP-47 tags for Intl formatters and Accept-Language. */
export const ADMIN_LOCALE_BCP47: Record<AdminLocale, string> = {
  en: 'en-GB',
  mk: 'mk-MK',
  sq: 'sq-AL',
};

export const ADMIN_LOCALE_OPEN_GRAPH: Record<AdminLocale, string> = {
  en: 'en_US',
  mk: 'mk_MK',
  sq: 'sq_AL',
};

const LOCALE_COOKIE_MAX_AGE = 60 * 60 * 24 * 365;

export function isAdminLocale(value: string | null | undefined): value is AdminLocale {
  return value != null && (ADMIN_LOCALES as readonly string[]).includes(value);
}

export function normalizeLocale(value: string | null | undefined): AdminLocale {
  return isAdminLocale(value) ? value : DEFAULT_ADMIN_LOCALE;
}

export function getAcceptLanguageHeader(locale: AdminLocale): string {
  return ADMIN_LOCALE_BCP47[locale];
}

export function readLocaleFromStorage(): AdminLocale | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = window.localStorage.getItem(ADMIN_LOCALE_STORAGE_KEY);
    return isAdminLocale(raw) ? raw : null;
  } catch {
    return null;
  }
}

export function writeLocaleToStorage(locale: AdminLocale): void {
  if (typeof window === 'undefined') return;
  try {
    window.localStorage.setItem(ADMIN_LOCALE_STORAGE_KEY, locale);
  } catch {
    // ignore storage write failures
  }
}

export function setLocaleCookieClient(locale: AdminLocale): void {
  if (typeof document === 'undefined') return;
  document.cookie = `${ADMIN_LOCALE_COOKIE}=${locale}; path=/; max-age=${LOCALE_COOKIE_MAX_AGE}; SameSite=Lax`;
}
