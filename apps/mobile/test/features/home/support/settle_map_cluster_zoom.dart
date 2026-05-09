import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/features/home/presentation/providers/map_cluster_effective_zoom_notifier.dart';

/// Waits until [mapClusterEffectiveZoomProvider] reaches [targetZoom] (ramp done).
Future<void> settleMapClusterEffectiveZoom(
  ProviderContainer container,
  double targetZoom,
) async {
  for (var i = 0; i < 160; i++) {
    final double z = container.read(mapClusterEffectiveZoomProvider);
    if ((z - targetZoom).abs() < 0.004) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 22));
  }
}
