import { BadRequestException } from '@nestjs/common';
import { DateTime } from 'luxon';

/** Civic calendar for same-day start/end bounds (North Macedonia). */
const PRODUCT_EVENT_CALENDAR_ZONE = 'Europe/Skopje';

/**
 * Default end instant: two hours after start in [PRODUCT_EVENT_CALENDAR_ZONE], capped to
 * the end of that local calendar day (23:59:59.999).
 */
export function defaultEndSameSkopjeCalendarDayUtc(scheduledAt: Date): Date {
  const start = DateTime.fromJSDate(scheduledAt, { zone: 'utc' }).setZone(PRODUCT_EVENT_CALENDAR_ZONE);
  const dayEnd = start.endOf('day');
  let end = start.plus({ hours: 2 });
  if (end > dayEnd) {
    end = dayEnd;
  }
  if (end <= start) {
    const bumped = start.plus({ minutes: 5 });
    end = bumped > dayEnd ? dayEnd : bumped;
  }
  if (end <= start) {
    end = dayEnd;
  }
  return end.toUTC().toJSDate();
}

/**
 * Events must start and end on the same local calendar day in [PRODUCT_EVENT_CALENDAR_ZONE],
 * with end strictly after start and not after the end of that local day.
 */
export function assertEndSameSkopjeCalendarDayUtc(params: { scheduledAt: Date; endAt: Date }): void {
  const start = DateTime.fromJSDate(params.scheduledAt, { zone: 'utc' }).setZone(
    PRODUCT_EVENT_CALENDAR_ZONE,
  );
  const end = DateTime.fromJSDate(params.endAt, { zone: 'utc' }).setZone(PRODUCT_EVENT_CALENDAR_ZONE);
  if (!start.isValid || !end.isValid) {
    throw new BadRequestException({
      code: 'INVALID_SCHEDULED_AT',
      message: 'Invalid schedule',
    });
  }
  if (end <= start) {
    throw new BadRequestException({
      code: 'INVALID_END_AT',
      message: 'endAt must be after scheduledAt',
    });
  }
  if (!end.hasSame(start, 'day')) {
    throw new BadRequestException({
      code: 'EVENTS_END_DIFFERENT_SKOPJE_CALENDAR_DAY',
      message: 'Event end must be on the same calendar day as the start (Europe/Skopje).',
    });
  }
  if (end > start.endOf('day')) {
    throw new BadRequestException({
      code: 'EVENTS_END_AFTER_SKOPJE_LOCAL_DAY',
      message: 'Event end must not be after 23:59 on the start day (Europe/Skopje).',
    });
  }
}
