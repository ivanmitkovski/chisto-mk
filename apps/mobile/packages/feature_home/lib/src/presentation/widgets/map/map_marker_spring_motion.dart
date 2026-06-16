import 'package:flutter/physics.dart';
import 'package:latlong2/latlong.dart';

/// Per-axis spring motion for one marker key (lat/lng geographic lerp).
class MapMarkerSpringAxis {
  MapMarkerSpringAxis({
    required this.start,
    required this.end,
    required SpringDescription spring,
    double velocity = 0,
  }) : _simulation = SpringSimulation(spring, start, end, velocity);

  final double start;
  final double end;
  SpringSimulation _simulation;

  double valueAt(double elapsedSeconds) {
    return _simulation.x(elapsedSeconds);
  }

  double velocityAt(double elapsedSeconds) => _simulation.dx(elapsedSeconds);

  bool isSettled(double elapsedSeconds, {double tolerance = 0.00001}) {
    final double v = velocityAt(elapsedSeconds).abs();
    final double d = (valueAt(elapsedSeconds) - end).abs();
    return v < tolerance && d < tolerance;
  }

  void retarget({
    required double from,
    required double to,
    required SpringDescription spring,
    required double elapsedSeconds,
  }) {
    final double velocity = velocityAt(elapsedSeconds);
    _simulation = SpringSimulation(spring, from, to, velocity);
  }
}

/// Drives lat/lng springs for one logical marker motion key.
class MapMarkerSpringPair {
  MapMarkerSpringPair({
    required LatLng start,
    required LatLng end,
    required SpringDescription spring,
    LatLng? velocity,
  }) : lat = MapMarkerSpringAxis(
         start: start.latitude,
         end: end.latitude,
         spring: spring,
         velocity: velocity?.latitude ?? 0,
       ),
       lng = MapMarkerSpringAxis(
         start: start.longitude,
         end: end.longitude,
         spring: spring,
         velocity: velocity?.longitude ?? 0,
       );

  MapMarkerSpringAxis lat;
  MapMarkerSpringAxis lng;
  double elapsed = 0;

  LatLng positionAt(double elapsedSeconds) {
    elapsed = elapsedSeconds;
    return LatLng(lat.valueAt(elapsedSeconds), lng.valueAt(elapsedSeconds));
  }

  bool isSettled(double elapsedSeconds) =>
      lat.isSettled(elapsedSeconds) && lng.isSettled(elapsedSeconds);

  void retarget({
    required LatLng from,
    required LatLng to,
    required SpringDescription spring,
  }) {
    lat.retarget(
      from: from.latitude,
      to: to.latitude,
      spring: spring,
      elapsedSeconds: elapsed,
    );
    lng.retarget(
      from: from.longitude,
      to: to.longitude,
      spring: spring,
      elapsedSeconds: elapsed,
    );
    elapsed = 0;
  }
}

LatLng latLngLerp(LatLng a, LatLng b, double t) {
  return LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );
}
