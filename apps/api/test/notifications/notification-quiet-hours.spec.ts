import { computeQuietHoursDeferral } from '../../src/notifications/util/notification-quiet-hours';

describe('notification-quiet-hours', () => {
  it('defers non-time-sensitive pushes during quiet window', () => {
    const now = new Date('2026-05-18T23:30:00.000Z');
    jest.useFakeTimers().setSystemTime(now);
    const defer = computeQuietHoursDeferral(
      {
        quietHoursStart: 22 * 60,
        quietHoursEnd: 7 * 60,
        quietHoursTimezone: 'UTC',
      },
      'active',
    );
    expect(defer).not.toBeNull();
    jest.useRealTimers();
  });

  it('does not defer time-sensitive pushes', () => {
    const defer = computeQuietHoursDeferral(
      {
        quietHoursStart: 22 * 60,
        quietHoursEnd: 7 * 60,
        quietHoursTimezone: 'UTC',
      },
      'time-sensitive',
    );
    expect(defer).toBeNull();
  });
});
