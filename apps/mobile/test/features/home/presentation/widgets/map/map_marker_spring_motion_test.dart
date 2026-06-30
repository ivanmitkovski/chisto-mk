import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/map/map_marker_spring_motion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('MapMarkerSpringPair retarget carries velocity on interrupt', () {
    final MapMarkerSpringPair pair = MapMarkerSpringPair(
      start: const LatLng(0, 0),
      end: const LatLng(1, 0),
      spring: AppMotion.mapMarkerSettleSpring,
    );
    pair.elapsed = 0.05;
    final double midLat = pair.lat.valueAt(pair.elapsed);
    final double midVel = pair.lat.velocityAt(pair.elapsed);
    expect(midLat, greaterThan(0));
    expect(midVel, greaterThan(0));

    final LatLng from = pair.positionAt(pair.elapsed);
    pair.retarget(
      from: from,
      to: const LatLng(2, 0),
      spring: AppMotion.mapMarkerSettleSpring,
    );
    expect(pair.lat.velocityAt(0), closeTo(midVel, 0.5));
  });
}
