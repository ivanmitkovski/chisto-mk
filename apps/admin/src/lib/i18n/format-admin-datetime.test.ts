import { describe, expect, it } from 'vitest';
import { formatAdminDateTime } from './format-admin-datetime';

describe('formatAdminDateTime', () => {
  it('formats with default dateStyle/timeStyle options', () => {
    const formatted = formatAdminDateTime('2026-06-06T12:30:00.000Z', 'en');
    expect(formatted.length).toBeGreaterThan(0);
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
