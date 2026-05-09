import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// Latest camera center/zoom for clustering and heatmap keys (updated from map events).
class MapCameraState {
  const MapCameraState({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
  });

  final double centerLat;
  final double centerLng;
  final double zoom;

  MapCameraState copyWith({
    double? centerLat,
    double? centerLng,
    double? zoom,
  }) {
    return MapCameraState(
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      zoom: zoom ?? this.zoom,
    );
  }
}

final mapCameraNotifierProvider =
    NotifierProvider<MapCameraNotifier, MapCameraState>(MapCameraNotifier.new);

class MapCameraNotifier extends Notifier<MapCameraState> {
  static const double _defaultZoom = 11;

  @override
  MapCameraState build() {
    return const MapCameraState(
      centerLat: ReportGeoFence.centerLat,
      centerLng: ReportGeoFence.centerLng,
      zoom: _defaultZoom,
    );
  }

  static bool _almost(double a, double b, [double eps = 1e-7]) =>
      (a - b).abs() < eps;

  void setCamera({
    required double centerLat,
    required double centerLng,
    required double zoom,
  }) {
    final MapCameraState s = state;
    if (_almost(centerLat, s.centerLat) &&
        _almost(centerLng, s.centerLng) &&
        _almost(zoom, s.zoom, 1e-5)) {
      return;
    }
    state = MapCameraState(
      centerLat: centerLat,
      centerLng: centerLng,
      zoom: zoom,
    );
  }
}
