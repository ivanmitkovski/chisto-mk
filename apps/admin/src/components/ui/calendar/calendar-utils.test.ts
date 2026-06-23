import { describe, expect, it } from 'vitest';
import {
  buildMonthGrid,
  compareIsoDates,
  formatIsoDate,
  isDateDisabled,
  parseIsoDate,
} from './calendar-utils';

describe('calendar-utils', () => {
  it('round-trips ISO dates in local time', () => {
    const date = new Date(2026, 5, 22);
    expect(formatIsoDate(date)).toBe('2026-06-22');
    expect(formatIsoDate(parseIsoDate('2026-06-22')!)).toBe('2026-06-22');
  });

  it('rejects invalid ISO dates', () => {
    expect(parseIsoDate('2026-13-01')).toBeNull();
    expect(parseIsoDate('bad')).toBeNull();
  });

  it('builds a 42-cell month grid', () => {
    const cells = buildMonthGrid(new Date(2026, 5, 1));
    expect(cells).toHaveLength(42);
    expect(cells.some((cell) => cell.iso === '2026-06-01' && cell.inMonth)).toBe(true);
    expect(cells.some((cell) => !cell.inMonth)).toBe(true);
  });

  it('compares ISO dates lexicographically', () => {
    expect(compareIsoDates('2026-01-01', '2026-02-01')).toBeLessThan(0);
    expect(compareIsoDates('2026-02-01', '2026-01-01')).toBeGreaterThan(0);
  });

  it('disables dates outside min/max', () => {
    const date = parseIsoDate('2026-06-15')!;
    expect(isDateDisabled(date, '2026-06-10', '2026-06-20')).toBe(false);
    expect(isDateDisabled(date, '2026-06-20')).toBe(true);
    expect(isDateDisabled(date, undefined, '2026-06-10')).toBe(true);
  });
});
