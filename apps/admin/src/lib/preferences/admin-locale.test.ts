import { describe, expect, it } from 'vitest';
import {
  ADMIN_LOCALE_BCP47,
  ADMIN_LOCALE_DISPLAY_NAMES,
  ADMIN_LOCALES,
  DEFAULT_ADMIN_LOCALE,
  getAcceptLanguageHeader,
  isAdminLocale,
  normalizeLocale,
} from './admin-locale';

describe('admin-locale', () => {
  it('normalizes supported locales', () => {
    expect(normalizeLocale('mk')).toBe('mk');
    expect(normalizeLocale('sq')).toBe('sq');
    expect(normalizeLocale('en')).toBe('en');
    expect(normalizeLocale('fr')).toBe(DEFAULT_ADMIN_LOCALE);
    expect(normalizeLocale(undefined)).toBe(DEFAULT_ADMIN_LOCALE);
  });

  it('validates locale membership', () => {
    for (const locale of ADMIN_LOCALES) {
      expect(isAdminLocale(locale)).toBe(true);
    }
    expect(isAdminLocale('de')).toBe(false);
  });

  it('maps BCP-47 Accept-Language headers', () => {
    expect(getAcceptLanguageHeader('en')).toBe(ADMIN_LOCALE_BCP47.en);
    expect(getAcceptLanguageHeader('mk')).toBe('mk-MK');
    expect(getAcceptLanguageHeader('sq')).toBe('sq-AL');
  });

  it('uses native display names', () => {
    expect(ADMIN_LOCALE_DISPLAY_NAMES.en).toBe('English');
    expect(ADMIN_LOCALE_DISPLAY_NAMES.mk).toBe('Македонски');
    expect(ADMIN_LOCALE_DISPLAY_NAMES.sq).toBe('Shqip');
  });
});
