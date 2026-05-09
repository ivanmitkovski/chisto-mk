import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/features/home/data/map_regions/map_region_catalog.dart';
import 'package:chisto_mobile/features/home/data/map_regions/map_region_names_catalog.dart';

void main() {
  test('all map region ids have explicit mk/sq/en names', () {
    final Set<String> expectedIds = <String>{
      ...mapRootRegionIds,
      ...mapSkopjeMunicipalityIds,
    };

    for (final String id in expectedIds) {
      expect(
        mapRegionHasAllLocaleNames(id),
        isTrue,
        reason: 'Missing explicit mk/sq/en translation for "$id".',
      );
    }
  });

  test('catalog returns non-empty names for mk/sq/en for each region id', () {
    final Set<String> expectedIds = <String>{
      ...mapRootRegionIds,
      ...mapSkopjeMunicipalityIds,
    };

    for (final String id in expectedIds) {
      final String? mk = mapRegionNameForLocale(id: id, localeName: 'mk');
      final String? sq = mapRegionNameForLocale(id: id, localeName: 'sq');
      final String? en = mapRegionNameForLocale(id: id, localeName: 'en');
      expect(mk, isNotNull, reason: 'Missing mk name for "$id".');
      expect(sq, isNotNull, reason: 'Missing sq name for "$id".');
      expect(en, isNotNull, reason: 'Missing en name for "$id".');
      expect(mk!.trim(), isNotEmpty, reason: 'Empty mk name for "$id".');
      expect(sq!.trim(), isNotEmpty, reason: 'Empty sq name for "$id".');
      expect(en!.trim(), isNotEmpty, reason: 'Empty en name for "$id".');
    }
  });

  test('unknown ids are not present in curated catalog', () {
    expect(mapRegionNameForLocale(id: 'unknown_region', localeName: 'mk'), isNull);
    expect(mapRegionNameForLocale(id: 'unknown_region', localeName: 'sq'), isNull);
    expect(mapRegionNameForLocale(id: 'unknown_region', localeName: 'en'), isNull);
  });
}
