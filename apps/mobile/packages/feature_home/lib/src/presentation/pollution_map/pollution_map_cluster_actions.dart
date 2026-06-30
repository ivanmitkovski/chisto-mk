part of 'package:feature_home/src/presentation/pollution_map/pollution_map_screen.dart';

extension _PollutionMapClusterActions on _PollutionMapScreenState {
  void _expandClusterToShowSites(List<LatLng> points) {
    if (points.isEmpty) return;
    final double minLat = points.map((p) => p.latitude).reduce(math.min);
    final double maxLat = points.map((p) => p.latitude).reduce(math.max);
    final double minLng = points.map((p) => p.longitude).reduce(math.min);
    final double maxLng = points.map((p) => p.longitude).reduce(math.max);
    const double minSpan = 0.002;
    final double spanLat = (maxLat - minLat).abs();
    final double spanLng = (maxLng - minLng).abs();
    final double padLat = spanLat < minSpan ? minSpan - spanLat : 0;
    final double padLng = spanLng < minSpan ? minSpan - spanLng : 0;
    final double spanDeg = math.sqrt(spanLat * spanLat + spanLng * spanLng);
    final bool isTightCluster = spanDeg < 0.03;
    _animatedMapController.animatedFitCamera(
      cameraFit: CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat - padLat / 2, minLng - padLng / 2),
          LatLng(maxLat + padLat / 2, maxLng + padLng / 2),
        ),
        padding: const EdgeInsets.all(MapLayoutTokens.clusterExpandPadding),
        maxZoom: 18,
        minZoom: isTightCluster ? MapLayoutTokens.minZoomClusterExpand : 6,
      ),
    );
  }

  void _handleClusterTap(ClusterBucket bucket, Map<String, LatLng> coords) {
    final List<LatLng> points = bucket.sites
        .map((PollutionSite s) => coords[s.id])
        .whereType<LatLng>()
        .toList();
    if (points.isEmpty) return;

    AppHaptics.medium(context);

    final Set<String> expandingIds = bucket.sites
        .map((PollutionSite s) => s.id)
        .toSet();
    final MapMarkerEntranceCache entranceCache = ref.read(
      mapMarkerEntranceCacheProvider,
    );
    entranceCache.resetForClusterExpansion(expandingIds);

    final double currentZoom = _animatedMapController.mapController.camera.zoom;
    final bool useSpiderfy =
        clusterNeedsSpiderfy(points: points, zoom: 18) ||
        (points.length > 1 &&
            clusterSpanDegrees(points) < 0.002 &&
            currentZoom >= 16);

    if (useSpiderfy && points.length > 1) {
      ref
          .read(mapClusterExpansionNotifierProvider.notifier)
          .beginSpiderfy(bucket: bucket, coordsById: coords, zoom: currentZoom);
      if (MediaQuery.supportsAnnounceOf(context)) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          context.l10n.mapClusterExpansionAnnounce(points.length),
          Directionality.of(context),
        );
      }
      return;
    }

    ref
        .read(mapClusterExpansionNotifierProvider.notifier)
        .beginExpansion(bucket: bucket, coordsById: coords);

    if (points.length == 1) {
      final double targetZoom =
          (_animatedMapController.mapController.camera.zoom + 2).clamp(
            3.0,
            18.0,
          );
      _preCommitTargetCamera(points.first, targetZoom);
      _animatedMapController.animateTo(dest: points.first, zoom: targetZoom);
    } else {
      _preCommitClusterExpansionBounds(points);
      _expandClusterToShowSites(points);
    }

    if (points.length > 1 && MediaQuery.supportsAnnounceOf(context)) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.l10n.mapClusterExpansionAnnounce(points.length),
        Directionality.of(context),
      );
    }
  }

  /// Immediately commits the target camera and jumps the effective clustering
  /// zoom so clustering recomputes in one frame instead of easing over ~500ms.
  void _preCommitTargetCamera(LatLng dest, double zoom) {
    _clusteringCamera.preCommitTargetCamera(
      dest.latitude,
      dest.longitude,
      zoom,
    );
  }

  /// Pre-computes the target camera for a bounds fit and commits it so
  /// clustering at the destination zoom runs while the camera is still moving.
  void _preCommitClusterExpansionBounds(List<LatLng> points) {
    try {
      final double minLat = points
          .map((LatLng p) => p.latitude)
          .reduce(math.min);
      final double maxLat = points
          .map((LatLng p) => p.latitude)
          .reduce(math.max);
      final double minLng = points
          .map((LatLng p) => p.longitude)
          .reduce(math.min);
      final double maxLng = points
          .map((LatLng p) => p.longitude)
          .reduce(math.max);
      const double minSpan = 0.002;
      final double spanLat = (maxLat - minLat).abs();
      final double spanLng = (maxLng - minLng).abs();
      final double padLat = spanLat < minSpan ? minSpan - spanLat : 0;
      final double padLng = spanLng < minSpan ? minSpan - spanLng : 0;
      final double spanDeg = math.sqrt(spanLat * spanLat + spanLng * spanLng);
      final bool isTightCluster = spanDeg < 0.03;
      final MapCamera target = CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat - padLat / 2, minLng - padLng / 2),
          LatLng(maxLat + padLat / 2, maxLng + padLng / 2),
        ),
        padding: const EdgeInsets.all(MapLayoutTokens.clusterExpandPadding),
        maxZoom: 18,
        minZoom: isTightCluster ? MapLayoutTokens.minZoomClusterExpand : 6,
      ).fit(_animatedMapController.mapController.camera);
      _preCommitTargetCamera(target.center, target.zoom);
    } catch (_) {
      // Camera may not be ready; clustering will catch up on MoveEnd.
    }
  }

  Future<void> _fitCameraToSearchGeoIntent(
    SiteMapSearchGeoIntent intent,
  ) async {
    final LatLngBounds bounds = LatLngBounds(
      LatLng(intent.minLat, intent.minLng),
      LatLng(intent.maxLat, intent.maxLng),
    );
    try {
      await _animatedMapController.animatedFitCamera(
        cameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: MapLayoutTokens.geoFitPadding,
          maxZoom: MapLayoutTokens.geoFitMaxZoomMunicipality,
          minZoom: MapLayoutTokens.geoFitMinZoomMunicipality,
        ),
      );
    } on Object catch (error, stackTrace) {
      AppLog.warn(
        'camera_fit_geo_intent',
        error: error,
        stackTrace: stackTrace,
        category: 'map',
      );
    }
  }

  Future<void> _fitCameraToGeoFilter(String? geoAreaId) async {
    final LatLngBounds bounds = geoAreaId == null
        ? _PollutionMapScreenState._macedoniaBounds
        : (_boundariesRepository.boundsFor(geoAreaId) ??
              MacedoniaMapRegions.boundsFor(geoAreaId) ??
              _PollutionMapScreenState._macedoniaBounds);
    final bool countryWide = geoAreaId == null;
    try {
      await _animatedMapController.animatedFitCamera(
        cameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: MapLayoutTokens.geoFitPadding,
          maxZoom: countryWide
              ? MapLayoutTokens.geoFitMaxZoomCountry
              : MapLayoutTokens.geoFitMaxZoomMunicipality,
          minZoom: countryWide
              ? MapLayoutTokens.geoFitMinZoomCountry
              : MapLayoutTokens.geoFitMinZoomMunicipality,
        ),
      );
    } on Object catch (error, stackTrace) {
      AppLog.warn(
        'camera_fit_geo_filter',
        error: error,
        stackTrace: stackTrace,
        category: 'map',
      );
    }
  }

  Future<void> _openFilterModal() async {
    final MapFilterState current = ref.read(mapFilterNotifierProvider);
    final List<PollutionSite> allSites = ref.read(
      mapSitesNotifierProvider.select((MapSitesState s) => s.sites),
    );
    final MapFilterState? result = await MapFilterSheet.show(
      context,
      current: current,
      allSites: allSites,
    );
    if (!mounted || result == null) {
      return;
    }
    ref.read(mapFilterNotifierProvider.notifier).applyFilters(result);
  }

  void _openSearchModal() {
    showMapBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => MapSearchModal(
        onResultTap: (PollutionSite site) async {
          Navigator.of(context).pop();
          final Map<String, LatLng> coords = ref.read(
            mapSiteCoordinatesProvider,
          );
          await _searchCoordinator.onSearchResultSelected(
            context: this.context,
            ref: ref,
            site: site,
            coordsById: coords,
            mapController: _animatedMapController,
            sitesRepository: ref.read(sitesRepositoryProvider),
          );
        },
        onGeoIntentSelected: (SiteMapSearchGeoIntent intent) {
          Navigator.of(context).pop();
          unawaited(_fitCameraToSearchGeoIntent(intent));
        },
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _openDirectionsForSite(PollutionSite site, Map<String, LatLng> coords) {
    showMapBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return DirectionsSheet(
          onAppleMapsTap: () {
            Navigator.of(context).pop();
            _launchDirections(site, coords, useAppleMaps: true);
          },
          onGoogleMapsTap: () {
            Navigator.of(context).pop();
            _launchDirections(site, coords, useAppleMaps: false);
          },
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  Future<void> _launchDirections(
    PollutionSite site,
    Map<String, LatLng> coords, {
    required bool useAppleMaps,
  }) async {
    final LatLng? point = coords[site.id];
    if (point == null) return;
    final LatLng? origin = ref.read(mapLocationNotifierProvider).userLocation;
    final String dest = '${point.latitude},${point.longitude}';
    final Uri url = useAppleMaps
        ? Uri.parse(
            'https://maps.apple.com/?daddr=$dest'
            '${origin != null ? '&saddr=${origin.latitude},${origin.longitude}' : ''}'
            '&dirflg=d',
          )
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$dest'
            '${origin != null ? '&origin=${origin.latitude},${origin.longitude}' : ''}',
          );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        _showDirectionsError();
      }
    } catch (_) {
      if (mounted) _showDirectionsError();
    }
  }

  void _showDirectionsError() {
    AppSnack.show(
      context,
      message: context.l10n.mapOpenMapsFailed,
      type: AppSnackType.warning,
    );
  }
}
