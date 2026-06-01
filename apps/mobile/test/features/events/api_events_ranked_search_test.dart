import 'package:feature_events/src/data/api_events_ranked_search.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildRankedEventsSearchBody', () {
    test('minimal body trims query and sets limit', () {
      const EcoEventSearchParams params = EcoEventSearchParams(
        query: '  river  ',
      );

      expect(
        buildRankedEventsSearchBody(
          params: params,
          nearLat: null,
          nearLng: null,
        ),
        <String, dynamic>{'query': 'river', 'limit': 30},
      );
    });

    test('includes geo when both nearLat and nearLng are set', () {
      const EcoEventSearchParams params = EcoEventSearchParams(query: 'lake');

      expect(
        buildRankedEventsSearchBody(
          params: params,
          nearLat: 41.99,
          nearLng: 21.43,
        ),
        <String, dynamic>{
          'query': 'lake',
          'limit': 30,
          'nearLat': 41.99,
          'nearLng': 21.43,
        },
      );
    });

    test('omits geo when only one coordinate is set', () {
      const EcoEventSearchParams params = EcoEventSearchParams(query: 'park');

      expect(
        buildRankedEventsSearchBody(
          params: params,
          nearLat: 41.99,
          nearLng: null,
        ),
        <String, dynamic>{'query': 'park', 'limit': 30},
      );
    });

    test('sorts and joins categories and statuses', () {
      final EcoEventSearchParams params = EcoEventSearchParams(
        query: 'cleanup',
        categories: <EcoEventCategory>{
          EcoEventCategory.riverAndLake,
          EcoEventCategory.generalCleanup,
        },
        statuses: <EcoEventStatus>{
          EcoEventStatus.inProgress,
          EcoEventStatus.upcoming,
        },
      );

      expect(
        buildRankedEventsSearchBody(
          params: params,
          nearLat: null,
          nearLng: null,
        ),
        <String, dynamic>{
          'query': 'cleanup',
          'limit': 30,
          'category': 'generalCleanup,riverAndLake',
          'status': 'inProgress,upcoming',
        },
      );
    });

    test('formats dateFrom and dateTo as YYYY-MM-DD', () {
      final EcoEventSearchParams params = EcoEventSearchParams(
        query: 'week',
        dateFrom: DateTime.utc(2026, 4, 1),
        dateTo: DateTime.utc(2026, 4, 30),
      );

      expect(
        buildRankedEventsSearchBody(
          params: params,
          nearLat: null,
          nearLng: null,
        ),
        <String, dynamic>{
          'query': 'week',
          'limit': 30,
          'dateFrom': '2026-04-01',
          'dateTo': '2026-04-30',
        },
      );
    });
  });

  group('parseRankedSearchSuggestions', () {
    test('table-driven: envelope edge cases', () {
      final List<({Map<String, dynamic>? json, List<String> expected})> cases =
          <({Map<String, dynamic>? json, List<String> expected})>[
            (json: null, expected: <String>[]),
            (
              json: <String, dynamic>{
                'suggestions': <dynamic>[1, 'ok', 'mk'],
              },
              expected: <String>['ok', 'mk'],
            ),
            (
              json: <String, dynamic>{'suggestions': 'not-a-list'},
              expected: <String>[],
            ),
            (
              json: <String, dynamic>{
                'suggestions': <String>['river', 'lake'],
              },
              expected: <String>['river', 'lake'],
            ),
          ];
      for (final ({Map<String, dynamic>? json, List<String> expected}) c
          in cases) {
        expect(parseRankedSearchSuggestions(c.json), c.expected);
      }
    });
  });
}
