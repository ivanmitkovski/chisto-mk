import 'package:chisto_mobile/features/home/data/map_realtime/map_sync_coordinator.dart';
import 'package:chisto_mobile/features/home/presentation/controllers/map_viewport_controller.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const MapViewportController c = MapViewportController();

  test('radiusKmForZoom tier boundaries', () {
    expect(c.radiusKmForZoom(20), 8);
    expect(c.radiusKmForZoom(14), 8);
    expect(c.radiusKmForZoom(13.9), 18);
    expect(c.radiusKmForZoom(12), 18);
    expect(c.radiusKmForZoom(11.9), 40);
    expect(c.radiusKmForZoom(10), 40);
    expect(c.radiusKmForZoom(9.9), 90);
    expect(c.radiusKmForZoom(8), 90);
    expect(c.radiusKmForZoom(7), 150);
  });

  test('buildViewportQuery clamps oversized visible bounds', () {
    final LatLngBounds huge = LatLngBounds(
      const LatLng(40.0, 20.0),
      const LatLng(45.0, 24.0),
    );
    final MapViewportQuery q = c.buildViewportQuery(
      latitude: 42.0,
      longitude: 22.0,
      zoom: 10,
      visibleBounds: huge,
      limit: 200,
    );
    expect(q.minLatitude, isNotNull);
    expect(q.maxLatitude, isNotNull);
    expect(q.minLongitude, isNotNull);
    expect(q.maxLongitude, isNotNull);
    final double latSpan = q.maxLatitude! - q.minLatitude!;
    final double lngSpan = q.maxLongitude! - q.minLongitude!;
    expect(latSpan, lessThanOrEqualTo(3.95 + 1e-6));
    expect(lngSpan, lessThanOrEqualTo(3.95 + 1e-6));
  });

  test('buildViewportQuery passes through small bounds', () {
    final LatLngBounds small = LatLngBounds(
      const LatLng(41.5, 21.5),
      const LatLng(41.7, 21.7),
    );
    final MapViewportQuery q = c.buildViewportQuery(
      latitude: 41.6,
      longitude: 21.6,
      zoom: 12,
      visibleBounds: small,
      limit: 120,
    );
    expect(q.minLatitude, small.south);
    expect(q.maxLatitude, small.north);
    expect(q.minLongitude, small.west);
    expect(q.maxLongitude, small.east);
  });
}
