import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Threshold in degrees from MK boundary to treat as "at fence" for haptics.
const double kLocationPickerFenceThresholdDegrees = 0.018;

bool locationPickerSameLatLng(LatLng? a, LatLng? b) {
  if (a == null || b == null) return false;
  return (a.latitude - b.latitude).abs() < 0.0001 &&
      (a.longitude - b.longitude).abs() < 0.0001;
}

bool locationPickerIsNearGeoFence(
  double lat,
  double lng, {
  double thresholdDegrees = kLocationPickerFenceThresholdDegrees,
}) {
  final double dLatMin = lat - ReportGeoFence.minLat;
  final double dLatMax = ReportGeoFence.maxLat - lat;
  final double dLngMin = lng - ReportGeoFence.minLng;
  final double dLngMax = ReportGeoFence.maxLng - lng;
  return dLatMin <= thresholdDegrees ||
      dLatMax <= thresholdDegrees ||
      dLngMin <= thresholdDegrees ||
      dLngMax <= thresholdDegrees;
}

LatLngBounds locationPickerMacedoniaBounds() {
  return LatLngBounds(
    LatLng(ReportGeoFence.minLat, ReportGeoFence.minLng),
    LatLng(ReportGeoFence.maxLat, ReportGeoFence.maxLng),
  );
}

LatLng locationPickerMacedoniaCenter() {
  return const LatLng(ReportGeoFence.centerLat, ReportGeoFence.centerLng);
}

String locationPickerCoordinateFallback(LatLng position) {
  return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
}
