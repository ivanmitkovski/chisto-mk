import 'package:chisto_infrastructure/core/config/map_tile_config.dart';
import 'package:chisto_infrastructure/shared/utils/cached_tile_provider.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/map/map_overlays.dart';
import 'package:feature_home/src/presentation/widgets/map/pollution_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Extracted map canvas that renders base map, user location, and marker layers.
class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    required this.mapController,
    required this.options,
    required this.useDarkTiles,
    required this.userLocation,
    required this.reduceMapAnimations,
    required this.showHeatmap,
    required this.heatmapLayer,
    required this.showEmptyFilterOverlay,
    required this.onResetFilters,
    required this.markersLayer,
    required this.highDpi,
    this.regionFence = const <Polygon>[],
    this.spiderfyPolylines = const <Polyline>[],
  });

  final MapController mapController;
  final MapOptions options;
  final bool useDarkTiles;
  final LatLng? userLocation;
  final bool reduceMapAnimations;
  final bool showHeatmap;
  final Widget heatmapLayer;
  final bool showEmptyFilterOverlay;
  final VoidCallback onResetFilters;

  /// Typically [RepaintBoundary] + [MarkerLayer] (may include geographic lerp).
  final Widget markersLayer;
  final bool highDpi;

  /// Optional geographic filter outline (drawn under markers, above heatmap).
  final List<Polygon> regionFence;
  final List<Polyline> spiderfyPolylines;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: options,
      children: <Widget>[
        TileLayer(
          urlTemplate: MapTileConfig.tileUrl(dark: useDarkTiles),
          subdomains: MapTileConfig.subdomains,
          maxNativeZoom: 20,
          userAgentPackageName: 'chisto_mobile',
          retinaMode: highDpi,
          keepBuffer: 3,
          panBuffer: 2,
          tileProvider: createCachedTileProvider(maxStaleDays: 30),
          tileDisplay: const TileDisplay.fadeIn(
            duration: Duration(milliseconds: 220),
            startOpacity: 0,
          ),
        ),
        if (userLocation != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: userLocation!,
                width: 80,
                height: 80,
                child: UserLocationDot(
                  key: ValueKey<LatLng>(userLocation!),
                  animate: !reduceMapAnimations,
                ),
              ),
            ],
          ),
        IgnorePointer(
          ignoring: !showHeatmap,
          child: AnimatedOpacity(
            opacity: showHeatmap ? 1 : 0,
            duration: reduceMapAnimations ? Duration.zero : AppMotion.standard,
            curve: AppMotion.smooth,
            child: heatmapLayer,
          ),
        ),
        if (regionFence.isNotEmpty)
          PolygonLayer(polygonCulling: true, polygons: regionFence),
        if (spiderfyPolylines.isNotEmpty)
          PolylineLayer(polylines: spiderfyPolylines),
        if (showEmptyFilterOverlay)
          EmptyFilterOverlay(
            onResetFilters: onResetFilters,
            useDarkTiles: useDarkTiles,
          ),
        // Marker list rebuild cost is dominated by [Marker] child builds, not repaints.
        // DevTools timeline on large N should guide per-marker diffing — avoid extra
        // [RepaintBoundary] layers unless profiling shows raster overdraw hotspots.
        RepaintBoundary(child: markersLayer),
      ],
    );
  }
}
