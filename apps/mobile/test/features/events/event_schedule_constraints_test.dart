import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_schedule_constraints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 4, 16, 14, 30);
  final DateTime today = DateUtils.dateOnly(now);
  final DateTime tomorrow = today.add(const Duration(days: 1));

  group('validateCreateOrUpcomingEditSchedule', () {
    test('allows tomorrow with typical range', () {
      expect(
        validateCreateOrUpcomingEditSchedule(
          dateOnly: tomorrow,
          start: const EventTime(hour: 9, minute: 0),
          end: const EventTime(hour: 11, minute: 0),
          now: now,
        ),
        isNull,
      );
    });

    test('rejects end before or equal to start', () {
      expect(
        validateCreateOrUpcomingEditSchedule(
          dateOnly: tomorrow,
          start: const EventTime(hour: 10, minute: 0),
          end: const EventTime(hour: 10, minute: 0),
          now: now,
        ),
        ScheduleValidationIssue.endNotAfterStart,
      );
    });

    test('rejects today start before now + lead', () {
      expect(
        validateCreateOrUpcomingEditSchedule(
          dateOnly: today,
          start: const EventTime(hour: 14, minute: 30),
          end: const EventTime(hour: 16, minute: 0),
          now: now,
        ),
        ScheduleValidationIssue.startTooSoon,
      );
    });

    test('allows today start at ceil(now + lead) on grid', () {
      final DateTime earliest = ceilToMinuteGrid(now.add(kEventScheduleMinLead));
      final EventTime start = EventTime(hour: earliest.hour, minute: earliest.minute);
      final DateTime endDt = earliest.add(const Duration(hours: 2));
      final EventTime end = EventTime(hour: endDt.hour, minute: endDt.minute);
      expect(
        validateCreateOrUpcomingEditSchedule(
          dateOnly: today,
          start: start,
          end: end,
          now: now,
        ),
        isNull,
      );
    });

    test('rejects date in the past', () {
      final DateTime past = today.subtract(const Duration(days: 1));
      expect(
        validateCreateOrUpcomingEditSchedule(
          dateOnly: past,
          start: const EventTime(hour: 10, minute: 0),
          end: const EventTime(hour: 12, minute: 0),
          now: now,
        ),
        ScheduleValidationIssue.startTooSoon,
      );
    });
  });

  group('validateInProgressEditSchedule', () {
    test('rejects end before now + lead even if start is in the past', () {
      expect(
        validateInProgressEditSchedule(
          dateOnly: today,
          start: const EventTime(hour: 8, minute: 0),
          end: const EventTime(hour: 14, minute: 33),
          now: now,
        ),
        ScheduleValidationIssue.endTooSoon,
      );
    });

    test('allows end after now + lead', () {
      const EventTime end = EventTime(hour: 18, minute: 0);
      expect(
        validateInProgressEditSchedule(
          dateOnly: today,
          start: const EventTime(hour: 8, minute: 0),
          end: end,
          now: now,
        ),
        isNull,
      );
    });
  });

  group('defaultStartEndForDate', () {
    test('today uses next grid slot and two hour span', () {
      final r = defaultStartEndForDate(dateOnly: today, now: now);
      expect(validateCreateOrUpcomingEditSchedule(
        dateOnly: today,
        start: r.start,
        end: r.end,
        now: now,
      ), isNull);
      expect(EcoEvent.isValidRange(r.start, r.end), isTrue);
    });
  });

  group('validateEditSchedule', () {
    test('upcoming matches create rules', () {
      expect(
        validateEditSchedule(
          status: EcoEventStatus.upcoming,
          dateOnly: today,
          start: const EventTime(hour: 14, minute: 30),
          end: const EventTime(hour: 16, minute: 0),
          now: now,
        ),
        ScheduleValidationIssue.startTooSoon,
      );
    });

    test('inProgress ignores start in past when end is valid', () {
      expect(
        validateEditSchedule(
          status: EcoEventStatus.inProgress,
          dateOnly: today,
          start: const EventTime(hour: 8, minute: 0),
          end: const EventTime(hour: 18, minute: 0),
          now: now,
        ),
        isNull,
      );
    });
  });

  group('ceilToMinuteGrid', () {
    test('rounds up to 5 minute boundary', () {
      final DateTime inDt = DateTime(2026, 1, 1, 10, 3);
      final DateTime out = ceilToMinuteGrid(inDt);
      expect(out, DateTime(2026, 1, 1, 10, 5));
    });
  });
}
