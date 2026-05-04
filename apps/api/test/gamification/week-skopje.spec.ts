import { DateTime } from 'luxon';
import {
  getSkopjeDayBoundsUtc,
  getSkopjeWeekBoundsUtc,
  SKOPJE_TZ,
} from '../../src/gamification/week-skopje';

describe('getSkopjeWeekBoundsUtc', () => {
  it('matches Luxon Monday start and Sunday end in Europe/Skopje', () => {
    const now = new Date('2026-04-01T14:30:00.000Z');
    const bounds = getSkopjeWeekBoundsUtc(now);

    const z = DateTime.fromJSDate(now, { zone: 'utc' }).setZone(SKOPJE_TZ);
    const mondayLocal = z.minus({ days: z.weekday - 1 }).startOf('day');
    const sundayEndLocal = mondayLocal.plus({ days: 6 }).endOf('day');

    expect(bounds.weekStartsAt.getTime()).toBe(mondayLocal.toUTC().toMillis());
    expect(bounds.weekEndsAt.getTime()).toBe(sundayEndLocal.toUTC().toMillis());
  });

  it('rolls correctly across a Sunday to Monday boundary in Skopje', () => {
    const sundaySkopje = DateTime.fromObject(
      { year: 2026, month: 4, day: 5, hour: 23, minute: 59 },
      { zone: SKOPJE_TZ },
    );
    const b1 = getSkopjeWeekBoundsUtc(sundaySkopje.toUTC().toJSDate());

    const mondaySkopje = sundaySkopje.plus({ days: 1 }).startOf('day');
    const b2 = getSkopjeWeekBoundsUtc(mondaySkopje.toUTC().toJSDate());

    expect(b1.weekStartsAt.toISOString()).not.toBe(b2.weekStartsAt.toISOString());
    expect(b2.weekStartsAt.getTime()).toBeGreaterThan(b1.weekStartsAt.getTime());
  });
});

describe('getSkopjeDayBoundsUtc', () => {
  it('returns start and end of the same calendar day in Europe/Skopje', () => {
    const now = new Date('2026-06-15T22:00:00.000Z');
    const { dayStartsAt, dayEndsAt } = getSkopjeDayBoundsUtc(now);
    const z = DateTime.fromJSDate(now, { zone: 'utc' }).setZone(SKOPJE_TZ);
    expect(dayStartsAt.getTime()).toBe(z.startOf('day').toUTC().toMillis());
    expect(dayEndsAt.getTime()).toBe(z.endOf('day').toUTC().toMillis());
    expect(dayEndsAt.getTime()).toBeGreaterThan(dayStartsAt.getTime());
  });
});
