import 'package:chisto_mobile/features/events/data/events_discovery_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late EventsDiscoveryPreferences prefs;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = const EventsDiscoveryPreferences();
  });

  group('EventsDiscoveryPreferences', () {
    test('readRecentSearches returns empty when none stored', () async {
      final List<String> result = await prefs.readRecentSearches();

      expect(result, isEmpty);
    });

    test('writeRecentSearches and readRecentSearches round-trip', () async {
      const List<String> queries = <String>['beach cleanup', 'park', 'river'];

      await prefs.writeRecentSearches(queries);
      final List<String> result = await prefs.readRecentSearches();

      expect(result, orderedEquals(queries));
    });

    test('recent searches serialization preserves order', () async {
      const List<String> queries = <String>['first', 'second', 'third'];

      await prefs.writeRecentSearches(queries);
      final List<String> result = await prefs.readRecentSearches();

      expect(result[0], 'first');
      expect(result[1], 'second');
      expect(result[2], 'third');
    });

    test('writeRecentSearches trims and deduplicates case-insensitively', () async {
      const List<String> queries = <String>[
        '  beach  ',
        'Beach',
        'park',
        '  PARK  ',
      ];

      await prefs.writeRecentSearches(queries);
      final List<String> result = await prefs.readRecentSearches();

      expect(result.length, 2);
      expect(result[0], 'beach');
      expect(result[1], 'park');
    });

    test('writeRecentSearches skips empty strings', () async {
      const List<String> queries = <String>['valid', '', '  ', 'another'];

      await prefs.writeRecentSearches(queries);
      final List<String> result = await prefs.readRecentSearches();

      expect(result.length, 2);
      expect(result, contains('valid'));
      expect(result, contains('another'));
    });

    test('writeRecentSearches caps at max recent searches', () async {
      final List<String> many = List<String>.generate(
        20,
        (int i) => 'query$i',
      );

      await prefs.writeRecentSearches(many);
      final List<String> result = await prefs.readRecentSearches();

      expect(result.length, lessThanOrEqualTo(8));
    });
  });
}
