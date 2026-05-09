import 'package:flutter/material.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_derived_providers.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';

double _heatmapWeightForStatus(String statusCode) {
  switch (statusCode) {
    case mapStatusDisputed:
    case mapStatusReported:
      return 2.8;
    case mapStatusVerified:
    case mapStatusCleanupScheduled:
    case mapStatusInProgress:
      return 2.0;
    case mapStatusCleaned:
      return 1.0;
    default:
      return 1.0;
  }
}

/// Derived heatmap layer from current filtered map sites.
class MapHeatmapLayer extends ConsumerWidget {
  const MapHeatmapLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PollutionSite> sites = ref.watch(mapFilteredSitesProvider);
    final Map<String, LatLng> coords = ref.watch(mapSiteCoordinatesProvider);
    final List<WeightedLatLng> data = <WeightedLatLng>[];
    for (final PollutionSite site in sites) {
      final LatLng? point = coords[site.id];
      if (point == null) {
        continue;
      }
      final double weight = _heatmapWeightForStatus(
        mapStatusCodeFromUnknown(site.statusCode ?? site.statusLabel),
      );
      data.add(WeightedLatLng(point, weight));
    }
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      child: HeatMapLayer(
        heatMapDataSource: InMemoryHeatMapDataSource(data: data),
        heatMapOptions: HeatMapOptions(
          gradient: HeatMapOptions.defaultGradient,
          minOpacity: 0.2,
          radius: 25,
        ),
      ),
    );
  }
}
