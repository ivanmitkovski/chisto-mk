/// <reference types="jest" />
import {
  formatDurationMinutes,
  formatOtpCodeValidityPhrase,
} from '../../../src/common/i18n/duration-copy';

describe('formatDurationMinutes', () => {
  it('uses full English words with pluralization', () => {
    expect(formatDurationMinutes('en', 1)).toBe('1 minute');
    expect(formatDurationMinutes('en', 5)).toBe('5 minutes');
    expect(formatDurationMinutes('en', 10)).toBe('10 minutes');
  });

  it('uses full Macedonian words with pluralization', () => {
    expect(formatDurationMinutes('mk', 1)).toBe('1 минута');
    expect(formatDurationMinutes('mk', 5)).toBe('5 минути');
    expect(formatDurationMinutes('mk', 21)).toBe('21 минута');
    expect(formatDurationMinutes('mk', 22)).toBe('22 минути');
  });

  it('uses full Albanian words with pluralization', () => {
    expect(formatDurationMinutes('sq', 1)).toBe('1 minute');
    expect(formatDurationMinutes('sq', 5)).toBe('5 minuta');
  });

  it('never abbreviates time units', () => {
    for (const locale of ['en', 'mk', 'sq'] as const) {
      const formatted = formatDurationMinutes(locale, 10);
      expect(formatted).not.toMatch(/\bmin\.|\bмин\./);
    }
  });

  it('rounds fractional input to at least 1 minute', () => {
    expect(formatDurationMinutes('en', 0.2)).toBe('1 minute');
  });
});

describe('formatOtpCodeValidityPhrase', () => {
  it('matches expected phrasing per locale', () => {
    expect(formatOtpCodeValidityPhrase('en', 5)).toBe('The code is valid for 5 minutes.');
    expect(formatOtpCodeValidityPhrase('mk', 5)).toBe('Кодот важи 5 минути.');
    expect(formatOtpCodeValidityPhrase('sq', 5)).toBe('Kodi skadon per 5 minuta.');
  });
});
