import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EcoEventSearchParams', () {
    test('offlineListCacheSuffix differs when query or filters change', () {
      const EcoEventSearchParams empty = EcoEventSearchParams();
      expect(empty.isEmpty, isTrue);
      expect(empty.offlineListCacheSuffix, isNotEmpty);

      final EcoEventSearchParams q1 = empty.copyWith(query: 'river');
      final EcoEventSearchParams q2 = empty.copyWith(query: 'lake');
      expect(q1.offlineListCacheSuffix, isNot(equals(q2.offlineListCacheSuffix)));

      final EcoEventSearchParams cats = EcoEventSearchParams(
        categories: <EcoEventCategory>{EcoEventCategory.generalCleanup},
      );
      final EcoEventSearchParams cats2 = EcoEventSearchParams(
        categories: <EcoEventCategory>{EcoEventCategory.riverAndLake},
      );
      expect(cats.offlineListCacheSuffix, isNot(equals(cats2.offlineListCacheSuffix)));
    });

    test('offlineListCacheSuffix is stable for same logical params', () {
      final EcoEventSearchParams a = EcoEventSearchParams(
        query: ' mk ',
        categories: <EcoEventCategory>{
          EcoEventCategory.riverAndLake,
          EcoEventCategory.generalCleanup,
        },
        statuses: <EcoEventStatus>{EcoEventStatus.upcoming, EcoEventStatus.inProgress},
        dateFrom: DateTime.utc(2026, 4, 1),
        dateTo: DateTime.utc(2026, 4, 30),
      );
      final EcoEventSearchParams b = EcoEventSearchParams(
        query: 'mk',
        categories: <EcoEventCategory>{
          EcoEventCategory.generalCleanup,
          EcoEventCategory.riverAndLake,
        },
        statuses: <EcoEventStatus>{EcoEventStatus.inProgress, EcoEventStatus.upcoming},
        dateFrom: DateTime.utc(2026, 4, 1),
        dateTo: DateTime.utc(2026, 4, 30),
      );
      expect(a.offlineListCacheSuffix, b.offlineListCacheSuffix);
    });
  });
}
