import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/features/home/presentation/providers/map_camera_notifier.dart';

/// Zoom level used exclusively for greedy map clustering thresholds.
///
/// Follows [mapCameraNotifierProvider] but eases toward each committed target over
/// many timer steps so greedy buckets split and merge progressively (with
/// [quantizeZoomForClusterRecompute] between isolates/UI). Pinch-zoom streams
/// throttled commits from the map layer so deltas stay small mid-gesture.
final mapClusterEffectiveZoomProvider =
    NotifierProvider<MapClusterEffectiveZoomNotifier, double>(
      MapClusterEffectiveZoomNotifier.new,
);

class MapClusterEffectiveZoomNotifier extends Notifier<double> {
  Timer? _timer;

  static const Duration _tick = Duration(milliseconds: 28);
  static const double _towardFine = 0.22;
  static const double _towardMid = 0.34;

  @override
  double build() {
    ref.listen<MapCameraState>(mapCameraNotifierProvider, (_, MapCameraState n) {
      _onTargetCommitted(n.zoom);
    });
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    return ref.read(mapCameraNotifierProvider).zoom;
  }

  /// Bypasses the easing ramp and sets the effective zoom immediately.
  /// Used during cluster expansion so clustering recomputes in one frame.
  void jumpTo(double zoom) {
    _timer?.cancel();
    _timer = null;
    state = zoom;
  }

  void _onTargetCommitted(double targetZoom) {
    final double current = state;
    final double delta = targetZoom - current;

    _timer?.cancel();
    _timer = null;

    if (delta.abs() < 0.0025) {
      state = targetZoom;
      return;
    }

    void tick(Timer _) {
      final double c = state;
      final double rem = (targetZoom - c).abs();
      if (rem < 0.0025) {
        state = targetZoom;
        _timer?.cancel();
        _timer = null;
        return;
      }
      final double t = rem > 0.42 ? _towardMid : _towardFine;
      state = c + (targetZoom - c) * t;
    }

    _timer = Timer.periodic(_tick, tick);
    // Advance one frame outside the notifying stack; avoids provider edge cases.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_timer?.isActive == true) tick(_timer!);
    });
  }

}
