import 'package:chisto_mobile/features/events/domain/discovery_skopje_week.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('skopjeCalendarWeekBoundsInclusive', () {
    test('Tuesday 2026-04-21 UTC maps to Mon Apr 20–Sun Apr 26 (UTC calendar dates)', () {
      final DateTime ref = DateTime.utc(2026, 4, 21, 15, 30);
      final ({DateTime dateFrom, DateTime dateTo}) bounds =
          skopjeCalendarWeekBoundsInclusive(ref);
      expect(bounds.dateFrom, DateTime.utc(2026, 4, 20));
      expect(bounds.dateTo, DateTime.utc(2026, 4, 26));
    });

    test('Monday Skopje week start: reference on Monday yields same Monday dateFrom', () {
      // 2026-04-20 is Monday in Skopje (same calendar date as UTC for midday).
      final DateTime ref = DateTime.utc(2026, 4, 20, 8, 0);
      final ({DateTime dateFrom, DateTime dateTo}) bounds =
          skopjeCalendarWeekBoundsInclusive(ref);
      expect(bounds.dateFrom, DateTime.utc(2026, 4, 20));
      expect(bounds.dateTo, DateTime.utc(2026, 4, 26));
    });
  });

  group('EcoEventSearchParams.discoveryThisSkopjeCalendarWeek', () {
    test('sets date bounds and default upcoming + inProgress statuses', () {
      final EcoEventSearchParams p = EcoEventSearchParams.discoveryThisSkopjeCalendarWeek(
        DateTime.utc(2026, 4, 21),
      );
      expect(p.dateFrom, DateTime.utc(2026, 4, 20));
      expect(p.dateTo, DateTime.utc(2026, 4, 26));
      expect(p.statuses, contains(EcoEventStatus.upcoming));
      expect(p.statuses, contains(EcoEventStatus.inProgress));
      expect(p.statuses.length, 2);
    });
  });
}
