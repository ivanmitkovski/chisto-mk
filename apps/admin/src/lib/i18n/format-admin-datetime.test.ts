import { describe, expect, it, vi, afterEach } from 'vitest';
import {
  adminCalendarDayKey,
  formatAdminActivityTimestamp,
  formatAdminDateTime,
} from './format-admin-datetime';

describe('formatAdminDateTime', () => {
  it('uses a fixed admin display timezone by default', () => {
    const formatted = formatAdminDateTime('2026-06-06T12:30:00.000Z', 'en');
    expect(formatted).toContain('2026');
  });

  it('allows granular options without mixing dateStyle/timeStyle', () => {
    expect(() =>
      formatAdminDateTime('2026-06-06T12:30:00.000Z', 'en', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      }),
    ).not.toThrow();
  });

  it('returns em dash for invalid dates', () => {
    expect(formatAdminDateTime('not-a-date', 'en')).toBe('—');
  });
});

describe('adminCalendarDayKey', () => {
  it('returns YYYY-MM-DD in admin timezone', () => {
    expect(adminCalendarDayKey('2026-06-28T22:30:00.000Z')).toBe('2026-06-29');
  });
});

describe('formatAdminActivityTimestamp', () => {
  const labels = { today: 'Today', yesterday: 'Yesterday' };

  afterEach(() => {
    vi.useRealTimers();
  });

  it('prefixes today with localized label and time', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-06-28T12:00:00.000Z'));
    const result = formatAdminActivityTimestamp('2026-06-28T08:15:00.000Z', 'en', labels);
    expect(result).toMatch(/^Today · /);
    expect(result).toContain(':');
  });

  it('prefixes yesterday with localized label and time', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-06-28T12:00:00.000Z'));
    const result = formatAdminActivityTimestamp('2026-06-27T15:00:00.000Z', 'en', labels);
    expect(result).toMatch(/^Yesterday · /);
  });

  it('includes month and day for older activity in the current year', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-06-28T12:00:00.000Z'));
    const result = formatAdminActivityTimestamp('2026-06-10T09:30:00.000Z', 'en', labels);
    expect(result).toMatch(/Jun/);
    expect(result).toContain('·');
    expect(result).not.toMatch(/^Today/);
    expect(result).not.toMatch(/^Yesterday/);
  });

  it('includes year when activity is from a prior year', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-06-28T12:00:00.000Z'));
    const result = formatAdminActivityTimestamp('2025-12-01T10:00:00.000Z', 'en', labels);
    expect(result).toContain('2025');
  });

  it('returns em dash for invalid timestamps', () => {
    expect(formatAdminActivityTimestamp('invalid', 'en', labels)).toBe('—');
  });
});
