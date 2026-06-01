import 'package:feature_home/src/presentation/utils/map_spiderfy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('computeSpiderfyLegOffsets is deterministic and sorted by id', () {
    final Map<String, LatLng> coords = <String, LatLng>{
      'b': const LatLng(41, 21),
      'a': const LatLng(41, 21),
      'c': const LatLng(41, 21),
    };
    final Map<String, LatLng> legs1 = computeSpiderfyLegOffsets(
      anchor: const LatLng(41, 21),
      memberCoords: coords,
      zoom: 16,
    );
    final Map<String, LatLng> legs2 = computeSpiderfyLegOffsets(
      anchor: const LatLng(41, 21),
      memberCoords: coords,
      zoom: 16,
    );
    expect(legs1, legs2);
    expect(legs1.keys.toList()..sort(), <String>['a', 'b', 'c']);
    expect(legs1.values.toSet().length, 3);
  });

  test('clusterNeedsSpiderfy true for co-located points', () {
    expect(
      clusterNeedsSpiderfy(
        points: const <LatLng>[LatLng(41, 21), LatLng(41, 21)],
        zoom: 18,
      ),
      isTrue,
    );
  });

  test('buildSpiderfyPolylines returns empty when reduce motion', () {
    expect(
      buildSpiderfyPolylines(
        anchor: const LatLng(41, 21),
        legs: const <String, LatLng>{'a': LatLng(41.001, 21)},
        reduceMotion: true,
      ),
      isEmpty,
    );
  });
}
