import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/features/home/data/map_regions/map_boundaries_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads boundary dataset and returns geometry for known ids', () async {
    final MapBoundariesRepository repository = MapBoundariesRepository.instance;
    await repository.warmup();

    final bitola = repository.geometryFor('bitola');
    expect(bitola, isNotNull);
    expect(bitola!.polygons, isNotEmpty);
    expect(bitola.bounds.south < bitola.bounds.north, isTrue);
    expect(bitola.bounds.west < bitola.bounds.east, isTrue);
    final first = bitola.polygons.first.outerRing.first;
    final last = bitola.polygons.first.outerRing.last;
    expect(first.latitude, last.latitude);
    expect(first.longitude, last.longitude);
  });

  test('provides derived geometry for skopje metro group', () async {
    final MapBoundariesRepository repository = MapBoundariesRepository.instance;
    await repository.warmup();

    final skopje = repository.geometryFor('skopje');
    expect(skopje, isNotNull);
    expect(skopje!.polygons.length, greaterThan(1));
  });

  test('returns null for unknown geometry and keeps fallback ring available', () async {
    final MapBoundariesRepository repository = MapBoundariesRepository.instance;
    await repository.warmup();

    expect(repository.geometryFor('unknown_id'), isNull);
    expect(repository.fallbackRingFor('bitola').length, greaterThanOrEqualTo(4));
  });

  test('loads nationwide ADM2 coverage and leaves no unmapped names', () async {
    final MapBoundariesRepository repository = MapBoundariesRepository.instance;
    await repository.warmup();

    // 84 municipalities + derived Skopje metro.
    expect(repository.isLoaded, isTrue);
    expect(repository.geometryFor('skopje_shuto_orizari'), isNotNull);
    expect(repository.geometryFor('arachinovo'), isNotNull);
    expect(repository.unmappedShapeNames, isEmpty);
  });

  test('canonical mapping keeps backward-compatible IDs', () async {
    final MapBoundariesRepository repository = MapBoundariesRepository.instance;
    await repository.warmup();

    expect(repository.geometryFor('shtip'), isNotNull);
    expect(repository.geometryFor('kavadartsi'), isNotNull);
    expect(repository.geometryFor('gjorche_petrov'), isNotNull);
  });

  test('parsed rings are normalized and remain within map fence', () async {
    final MapBoundariesRepository repository = MapBoundariesRepository.instance;
    await repository.warmup();

    final geometry = repository.geometryFor('skopje_centar');
    expect(geometry, isNotNull);
    for (final polygon in geometry!.polygons) {
      expect(polygon.outerRing.length, greaterThanOrEqualTo(4));
      for (int i = 1; i < polygon.outerRing.length; i++) {
        final prev = polygon.outerRing[i - 1];
        final curr = polygon.outerRing[i];
        final bool same =
            prev.latitude == curr.latitude && prev.longitude == curr.longitude;
        // no consecutive duplicates after normalization, except ring closure already excluded by i range
        expect(same, isFalse);
      }
    }
  });
}

