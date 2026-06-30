import 'package:feature_home/src/presentation/providers/map_camera_notifier.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Zoom level used exclusively for greedy map clustering thresholds.
///
/// Follows [mapCameraNotifierProvider] but eases toward each committed target over
/// frame-aligned steps so greedy buckets split and merge progressively (with
/// [quantizeZoomForClusterRecompute] between isolates/UI). Pinch-zoom streams
/// throttled commits from the map layer so deltas stay small mid-gesture.
final mapClusterEffectiveZoomProvider =
    NotifierProvider<MapClusterEffectiveZoomNotifier, double>(
      MapClusterEffectiveZoomNotifier.new,
    );

class MapClusterEffectiveZoomNotifier extends Notifier<double> {
  double? _targetZoom;
  bool _frameScheduled = false;

  static const double _towardFine = 0.22;
  static const double _towardMid = 0.34;

  @override
  double build() {
    ref.listen<MapCameraState>(mapCameraNotifierProvider, (
      _,
      MapCameraState n,
    ) {
      _onTargetCommitted(n.zoom);
    });
    ref.onDispose(() {
      _targetZoom = null;
      _frameScheduled = false;
    });
    return ref.read(mapCameraNotifierProvider).zoom;
  }

  /// Bypasses the easing ramp and sets the effective zoom immediately.
  /// Used during cluster expansion so clustering recomputes in one frame.
  void jumpTo(double zoom) {
    _targetZoom = null;
    _frameScheduled = false;
    state = zoom;
  }

  void _onTargetCommitted(double targetZoom) {
    final double current = state;
    final double delta = targetZoom - current;

    if (delta.abs() < 0.0025) {
      _targetZoom = null;
      _frameScheduled = false;
      state = targetZoom;
      return;
    }

    _targetZoom = targetZoom;
    _scheduleFrame();
  }

  void _scheduleFrame() {
    if (_frameScheduled) {
      return;
    }
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameScheduled = false;
      final double? target = _targetZoom;
      if (target == null) {
        return;
      }
      final double c = state;
      final double rem = (target - c).abs();
      if (rem < 0.0025) {
        _targetZoom = null;
        state = target;
        return;
      }
      final double t = rem > 0.42 ? _towardMid : _towardFine;
      state = c + (target - c) * t;
      _scheduleFrame();
    });
  }
}
