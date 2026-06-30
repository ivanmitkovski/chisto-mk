import {
  formatRelativeTimeSince,
  localeFromAcceptLanguage,
} from '../../src/common/utils/format-relative-time-since';

describe('localeFromAcceptLanguage', () => {
  it('returns en when header is missing', () => {
    expect(localeFromAcceptLanguage(undefined)).toBe('en');
    expect(localeFromAcceptLanguage('')).toBe('en');
  });

  it('parses the first tag from a standard header', () => {
    expect(localeFromAcceptLanguage('mk-MK,en;q=0.9')).toBe('mk-MK');
  });

  it('falls back to en for fetch wildcard Accept-Language', () => {
    expect(localeFromAcceptLanguage('*')).toBe('en');
    expect(localeFromAcceptLanguage('*, en;q=0.9')).toBe('en');
  });
});

describe('formatRelativeTimeSince', () => {
  it('does not throw for wildcard locale', () => {
    const now = new Date('2026-05-28T12:00:00.000Z');
    const createdAt = new Date('2026-05-28T11:00:00.000Z');
    expect(() => formatRelativeTimeSince(createdAt, now, '*')).not.toThrow();
  });
});
