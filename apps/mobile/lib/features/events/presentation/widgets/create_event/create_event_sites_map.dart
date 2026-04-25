import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/shared/utils/cached_tile_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Compact flutter_map for picking or previewing cleanup sites in create-event flows.
/// Reuses Carto light raster tiles and cached tile provider (same stack as the home map).
class CreateEventSitesMap extends StatefulWidget {
  const CreateEventSitesMap({
    super.key,
    required this.sites,
    this.selectedSiteId,
    required this.onSiteTap,
    required this.height,
    this.interactive = true,
  });

  final List<EventSiteSummary> sites;
  final String? selectedSiteId;
  final ValueChanged<EventSiteSummary> onSiteTap;
  final double height;
  final bool interactive;

  @override
  State<CreateEventSitesMap> createState() => _CreateEventSitesMapState();
}

class _CreateEventSitesMapState extends State<CreateEventSitesMap> {
  final MapController _mapController = MapController();
  Timer? _fitDebounce;

  static final LatLngBounds _macedoniaBounds = LatLngBounds(
    LatLng(ReportGeoFence.minLat, ReportGeoFence.minLng),
    LatLng(ReportGeoFence.maxLat, ReportGeoFence.maxLng),
  );

  List<EventSiteSummary> get _mappable {
    return widget.sites
        .where(
          (EventSiteSummary s) => s.latitude != null && s.longitude != null,
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    _fitDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CreateEventSitesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameSitePoints(oldWidget.sites, widget.sites)) {
      _scheduleFit();
    }
  }

  bool _sameSitePoints(List<EventSiteSummary> a, List<EventSiteSummary> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].latitude != b[i].latitude ||
          a[i].longitude != b[i].longitude) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleFit());
  }

  void _scheduleFit() {
    _fitDebounce?.cancel();
    _fitDebounce = Timer(const Duration(milliseconds: 80), _fitToMarkers);
  }

  void _fitToMarkers() {
    if (!mounted) {
      return;
    }
    final List<EventSiteSummary> m = _mappable;
    if (m.isEmpty) {
      return;
    }
    final List<LatLng> points = m
        .map((EventSiteSummary s) => LatLng(s.latitude!, s.longitude!))
        .toList(growable: false);
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final LatLng p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    const double minSpan = 0.002;
    final double spanLat = (maxLat - minLat).abs();
    final double spanLng = (maxLng - minLng).abs();
    final double padLat = spanLat < minSpan ? minSpan - spanLat : 0;
    final double padLng = spanLng < minSpan ? minSpan - spanLng : 0;
    final LatLng southWest = LatLng(minLat - padLat / 2, minLng - padLng / 2);
    final LatLng northEast = LatLng(maxLat + padLat / 2, maxLng + padLng / 2);
    final LatLngBounds bounds = LatLngBounds(southWest, northEast);
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(AppSpacing.lg),
          maxZoom: 16,
          minZoom: 5,
        ),
      );
    } on Object {
      // Map surface may not be ready yet; a later onMapReady schedules again.
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<EventSiteSummary> m = _mappable;
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final bool highDpi = dpr > 1.0;

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(
              ReportGeoFence.centerLat,
              ReportGeoFence.centerLng,
            ),
            initialZoom: 11,
            maxZoom: 18,
            backgroundColor: AppColors.mapLightPaper,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: _macedoniaBounds,
            ),
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? (InteractiveFlag.drag |
                      InteractiveFlag.flingAnimation |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom)
                  : InteractiveFlag.none,
            ),
            onMapReady: _scheduleFit,
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const <String>['a', 'b', 'c', 'd'],
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
            MarkerLayer(
              markers: <Marker>[
                for (final EventSiteSummary site in m)
                  Marker(
                    point: LatLng(site.latitude!, site.longitude!),
                    width: 40,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: widget.interactive
                          ? () => widget.onSiteTap(site)
                          : null,
                      child: Icon(
                        CupertinoIcons.location_solid,
                        size: widget.interactive ? 34 : 30,
                        color: site.id == widget.selectedSiteId
                            ? AppColors.primaryDark
                            : AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
