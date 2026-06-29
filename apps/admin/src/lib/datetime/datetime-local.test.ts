import { describe, expect, it } from 'vitest';
import {
  compareTime,
  formatTimeValue,
  fromDatetimeLocalValue,
  isMinuteDisabled,
  joinDatetimeLocal,
  snapTimeToStep,
  splitDatetimeLocal,
  toDatetimeLocalValue,
} from './datetime-local';

describe('datetime-local', () => {
  it('round-trips ISO through datetime-local', () => {
    const iso = '2026-06-24T14:30:00.000Z';
    const local = toDatetimeLocalValue(iso);
    expect(local).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/);
    expect(fromDatetimeLocalValue(local)).toBeTruthy();
  });

  it('splits and joins datetime-local parts', () => {
    expect(splitDatetimeLocal('2026-06-24T09:15')).toEqual({
      date: '2026-06-24',
      time: '09:15',
    });
    expect(joinDatetimeLocal('2026-06-24', '09:15')).toBe('2026-06-24T09:15');
  });

  it('returns null for empty fromDatetimeLocalValue', () => {
    expect(fromDatetimeLocalValue('')).toBeNull();
    expect(fromDatetimeLocalValue('   ')).toBeNull();
  });
});

describe('time helpers', () => {
  it('snaps minutes to step', () => {
    expect(snapTimeToStep('10:07', 5)).toBe('10:05');
    expect(snapTimeToStep('10:08', 5)).toBe('10:10');
  });

  it('compares times', () => {
    expect(compareTime('09:30', '10:00')).toBeLessThan(0);
    expect(compareTime('10:00', '10:00')).toBe(0);
  });

  it('disables minutes before min on same hour', () => {
    expect(isMinuteDisabled(15, 14, '14:30')).toBe(true);
    expect(isMinuteDisabled(30, 14, '14:30')).toBe(false);
  });

  it('formats padded time', () => {
    expect(formatTimeValue(9, 5)).toBe('09:05');
  });
});
