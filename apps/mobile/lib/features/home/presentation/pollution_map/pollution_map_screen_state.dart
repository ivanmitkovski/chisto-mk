part of 'package:chisto_mobile/features/home/presentation/pollution_map/pollution_map_screen.dart';

class _PollutionMapScreenState extends ConsumerState<PollutionMapScreen>
    with TickerProviderStateMixin {
  final MapViewportController _viewportController =
      const MapViewportController();
  final MapSearchCoordinator _searchCoordinator = const MapSearchCoordinator();
  final MapBoundariesRepository _boundariesRepository =
      MapBoundariesRepository.instance;
  late final AnimatedMapController _animatedMapController =
      AnimatedMapController(
        vsync: this,
        duration: AppMotion.mapCameraFly,
        curve: AppMotion.mapCameraFlyCurve,
      );

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  late final Animation<double> _legendOpacity = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
  );
  late final Animation<Offset> _legendSlide =
      Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
        ),
      );

  static final LatLngBounds _macedoniaBounds = LatLngBounds(
    LatLng(ReportGeoFence.minLat, ReportGeoFence.minLng),
    LatLng(ReportGeoFence.maxLat, ReportGeoFence.maxLng),
  );

  late final MapLocationNotifier _mapLocationNotifier;
  bool _showTileLoadingOverlay = true;
  bool _mapLayoutReady = false;
  Timer? _tileOverlaySoftDismissTimer;
  Timer? _tileOverlayMaxTimer;
  Timer? _viewportMoveDebounce;
  Timer? _viewportMoveEndMicroDebounce;

  /// Batches [mapCameraNotifierProvider] writes so clustering/markers do not rebuild on every drag frame.
  Timer? _mapCameraClusteringDebounce;
  bool _hasAttemptedInitialLocate = false;
  final ValueNotifier<double> _mapRotationNotifier = ValueNotifier<double>(0);

  /// Previous cluster partition (see [MapMarkerEntranceCache.clusterPartitionSignature]).
  String? _clusterPartitionSig;
  List<ClusterBucket> _prevBucketsForEntrance = const <ClusterBucket>[];
  String? _lastMapSitesPrefetchSig;
  String? _lastClusterEntranceSig;

  @override
  void initState() {
    super.initState();
    _mapLocationNotifier = ref.read(mapLocationNotifierProvider.notifier);
    widget.pendingSiteFocus?.addListener(_onPendingSiteFocusChanged);
    unawaited(_warmupBoundaryData());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(mapSitesNotifierProvider.notifier).setActive(widget.isActive);
      if (widget.isActive) {
        await _mapLocationNotifier.startForegroundTracking();
      }
      _syncMapViewport(immediate: true);
      await _tryInitialLocate();
      await _tryApplyPendingSiteFocus();
    });
  }

  Future<void> _warmupBoundaryData() async {
    await _boundariesRepository.warmup();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant PollutionMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pendingSiteFocus != widget.pendingSiteFocus) {
      oldWidget.pendingSiteFocus?.removeListener(_onPendingSiteFocusChanged);
      widget.pendingSiteFocus?.addListener(_onPendingSiteFocusChanged);
    }
    if (oldWidget.isActive != widget.isActive) {
      // Riverpod: do not call notifiers from [didUpdateWidget] — it runs during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(mapSitesNotifierProvider.notifier).setActive(widget.isActive);
        if (widget.isActive) {
          unawaited(_mapLocationNotifier.startForegroundTracking());
          _syncMapViewport(immediate: true);
        } else {
          ref.read(mapClusterExpansionNotifierProvider.notifier).reset();
          unawaited(_mapLocationNotifier.stopForegroundTracking());
        }
      });
    }
  }

  @override
  void dispose() {
    _viewportMoveDebounce?.cancel();
    _viewportMoveEndMicroDebounce?.cancel();
    _mapCameraClusteringDebounce?.cancel();
    _tileOverlaySoftDismissTimer?.cancel();
    _tileOverlayMaxTimer?.cancel();
    widget.pendingSiteFocus?.removeListener(_onPendingSiteFocusChanged);
    widget.pendingSiteFocus?.value = null;
    unawaited(_mapLocationNotifier.stopForegroundTracking());
    _mapRotationNotifier.dispose();
    _entranceController.dispose();
    _animatedMapController.dispose();
    super.dispose();
  }

  void _onPendingSiteFocusChanged() {
    if (!mounted) {
      return;
    }
    if (widget.pendingSiteFocus?.value != null) {
      unawaited(_tryApplyPendingSiteFocus());
    }
  }

  double _mapPrefetchOverscanLogicalPx() {
    const double base = MapLayoutTokens.prefetchOverscanBasePt;
    final MediaQueryData? mq = MediaQuery.maybeOf(context);
    if (mq == null) return base;
    return mq.textScaler.scale(base).clamp(52.0, 118.0);
  }

  bool _isMapCameraNotReady(Object error) {
    return error is Error &&
        error.toString().startsWith('LateInitializationError:');
  }

  MapViewportQuery _currentMapViewportQuery() {
    final MapController mc = _animatedMapController.mapController;
    final MapCamera camera;
    try {
      camera = mc.camera;
    } catch (e) {
      if (_isMapCameraNotReady(e)) {
        final bool includeArchived = ref
            .read(mapFilterNotifierProvider)
            .includeArchived;
        return MapViewportQuery(
          latitude: ReportGeoFence.centerLat,
          longitude: ReportGeoFence.centerLng,
          radiusKm: _viewportController.radiusKmForZoom(
            MapLayoutTokens.zoomCity,
          ),
          limit: 250,
          zoom: MapLayoutTokens.zoomCity,
          includeArchived: includeArchived,
        );
      }
      rethrow;
    }
    final LatLng center = camera.center;
    final LatLngBounds? visible =
        camera.nonRotatedSize.x > 0 && camera.nonRotatedSize.y > 0
        ? _viewportController.prefetchQueryBoundsFromCamera(
            camera,
            _mapPrefetchOverscanLogicalPx(),
            camera.visibleBounds,
          )
        : null;
    final bool includeArchived = ref
        .read(mapFilterNotifierProvider)
        .includeArchived;
    return _viewportController.buildViewportQuery(
      latitude: center.latitude,
      longitude: center.longitude,
      zoom: camera.zoom,
      visibleBounds: visible,
      limit: 250,
      includeArchived: includeArchived,
    );
  }

  void _syncMapViewport({required bool immediate}) {
    final n = ref.read(mapSitesNotifierProvider.notifier);
    n.updateViewport(_currentMapViewportQuery());
    n.requestSync(immediate: immediate);
  }

  void _commitMapCameraNotifier(MapCamera cam) {
    ref.read(mapCameraNotifierProvider.notifier).setCamera(
          centerLat: cam.center.latitude,
          centerLng: cam.center.longitude,
          zoom: cam.zoom,
        );
  }

  void _debounceCommitMapCameraForClustering(MapCamera cam, Duration delay) {
    _mapCameraClusteringDebounce?.cancel();
    _mapCameraClusteringDebounce = Timer(delay, () {
      _mapCameraClusteringDebounce = null;
      if (!mounted) {
        return;
      }
      _commitMapCameraNotifier(cam);
    });
  }

  /// Feeds clustering/heatmap keyed providers only when movement settles (drag frame spam would rebuild all markers).
  void _maybeUpdateMapCameraNotifierForClustering(MapEvent event) {
    if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd ||
        event is MapEventRotateEnd ||
        event is MapEventFlingAnimationNotStarted) {
      _mapCameraClusteringDebounce?.cancel();
      _mapCameraClusteringDebounce = null;
      _commitMapCameraNotifier(event.camera);
      return;
    }

    if (event is MapEventNonRotatedSizeChange || event is MapEventScrollWheelZoom) {
      _debounceCommitMapCameraForClustering(
        event.camera,
        const Duration(milliseconds: 160),
      );
      return;
    }

    /// Pinch / rotate-zoom: periodic commits so greedy clustering thresholds track
    /// the gesture instead of popping once on [MapEventMoveEnd].
    if (event is MapEventMove && event.source == MapEventSource.onMultiFinger) {
      _debounceCommitMapCameraForClustering(
        event.camera,
        const Duration(milliseconds: 46),
      );
      return;
    }

    // Programmatic flies (animateTo, fitCamera) emit many intermediate moves — coalesce once motion stops.
    if (event is MapEventMove &&
        event.source == MapEventSource.mapController) {
      _debounceCommitMapCameraForClustering(
        event.camera,
        const Duration(milliseconds: 200),
      );
    }
  }

  Future<void> _tryInitialLocate() async {
    if (_hasAttemptedInitialLocate) return;
    _hasAttemptedInitialLocate = true;
    await ref.read(mapLocationNotifierProvider.notifier).tryInitialLocate();
    if (!mounted) return;
    final LatLng? location = ref.read(mapLocationNotifierProvider).userLocation;
    if (location == null) return;
    await _animatedMapController.animateTo(
      dest: location,
      zoom: MapLayoutTokens.zoomCity,
    );
    _syncMapViewport(immediate: false);
  }

  Future<void> _tryApplyPendingSiteFocus() async {
    final ValueNotifier<String?>? notifier = widget.pendingSiteFocus;
    if (!mounted || notifier == null || notifier.value == null) return;
    final String id = notifier.value!;
    await ref
        .read(mapSelectionNotifierProvider.notifier)
        .runPendingFocus(
          siteId: id,
          onLocated: (site, point) {
            if (!mounted) return;
            ref.read(mapSelectionNotifierProvider.notifier).select(site);
            AppHaptics.tap(context);
            _animatedMapController.animateTo(dest: point, zoom: 14.5);
          },
          onUnavailable: () {
            if (!mounted) return;
            AppSnack.show(
              context,
              message: context.l10n.mapSiteNotOnMapSnack,
              type: AppSnackType.warning,
            );
          },
          onError: () {
            if (!mounted) return;
            AppSnack.show(
              context,
              message: context.l10n.mapOpenLocationFailedSnack,
              type: AppSnackType.warning,
            );
          },
        );
    if (!mounted) return;
    if (notifier.value == id) notifier.value = null;
    widget.onPendingSiteFocusConsumed?.call();
  }

  Future<void> _openSiteDetail(PollutionSite site) async {
    AppHaptics.light(context);
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PollutionSiteDetailScreen(
          site: site,
          skipInitialRefresh: true,
        ),
      ),
    );
  }

  Future<void> _handleLocateMe() async {
    final GeoPosition? pos = await ref
        .read(mapLocationNotifierProvider.notifier)
        .locateUserBest();
    if (!mounted) return;
    if (pos == null) {
      AppHaptics.warning(context);
      return;
    }
    AppHaptics.success(context);
    await _animatedMapController.animateTo(
      dest: LatLng(pos.latitude, pos.longitude),
      zoom: 16.5,
    );
    _syncMapViewport(immediate: false);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      ref.read(mapLocationNotifierProvider.notifier).clearLocationJustFound();
    }
  }

  void _prefetchMapPinImages(List<PollutionSite> sites) {
    final SiteImagePrefetchQueue queue = SiteImagePrefetchQueue.instance;
    int remaining = MapLayoutTokens.prefetchBudget;
    for (final PollutionSite site in sites) {
      if (remaining <= 0) break;
      final String? url = site.primaryImageUrl;
      if (url == null) continue;
      if (!url.startsWith('http://') && !url.startsWith('https://')) continue;
      queue.enqueue(context, imageProviderForMapPin(url));
      remaining -= 1;
    }
  }

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

    final Set<String> expandingIds =
        bucket.sites.map((PollutionSite s) => s.id).toSet();
    MapMarkerEntranceCache.instance.resetForClusterExpansion(expandingIds);
    ref
        .read(mapClusterExpansionNotifierProvider.notifier)
        .beginExpansion(bucket: bucket, coordsById: coords);

    if (points.length == 1) {
      final double targetZoom =
          (_animatedMapController.mapController.camera.zoom + 2)
              .clamp(3.0, 18.0);
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
    _mapCameraClusteringDebounce?.cancel();
    _mapCameraClusteringDebounce = null;
    ref.read(mapClusterEffectiveZoomProvider.notifier).jumpTo(zoom);
    ref.read(mapCameraNotifierProvider.notifier).setCamera(
          centerLat: dest.latitude,
          centerLng: dest.longitude,
          zoom: zoom,
        );
  }

  /// Pre-computes the target camera for a bounds fit and commits it so
  /// clustering at the destination zoom runs while the camera is still moving.
  void _preCommitClusterExpansionBounds(List<LatLng> points) {
    try {
      final double minLat =
          points.map((LatLng p) => p.latitude).reduce(math.min);
      final double maxLat =
          points.map((LatLng p) => p.latitude).reduce(math.max);
      final double minLng =
          points.map((LatLng p) => p.longitude).reduce(math.min);
      final double maxLng =
          points.map((LatLng p) => p.longitude).reduce(math.max);
      const double minSpan = 0.002;
      final double spanLat = (maxLat - minLat).abs();
      final double spanLng = (maxLng - minLng).abs();
      final double padLat = spanLat < minSpan ? minSpan - spanLat : 0;
      final double padLng = spanLng < minSpan ? minSpan - spanLng : 0;
      final double spanDeg =
          math.sqrt(spanLat * spanLat + spanLng * spanLng);
      final bool isTightCluster = spanDeg < 0.03;
      final MapCamera target = CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat - padLat / 2, minLng - padLng / 2),
          LatLng(maxLat + padLat / 2, maxLng + padLng / 2),
        ),
        padding:
            const EdgeInsets.all(MapLayoutTokens.clusterExpandPadding),
        maxZoom: 18,
        minZoom:
            isTightCluster ? MapLayoutTokens.minZoomClusterExpand : 6,
      ).fit(_animatedMapController.mapController.camera);
      _preCommitTargetCamera(target.center, target.zoom);
    } catch (_) {
      // Camera may not be ready; clustering will catch up on MoveEnd.
    }
  }

  Future<void> _fitCameraToSearchGeoIntent(SiteMapSearchGeoIntent intent) async {
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
    } catch (_) {}
  }

  Future<void> _fitCameraToGeoFilter(String? geoAreaId) async {
    final LatLngBounds bounds = geoAreaId == null
        ? _macedoniaBounds
        : (_boundariesRepository.boundsFor(geoAreaId) ??
              MacedoniaMapRegions.boundsFor(geoAreaId) ??
              _macedoniaBounds);
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
    } catch (_) {}
  }

  void _openFilterModal({
    required Set<String> statuses,
    required Set<String> pollutionTypes,
    required String? geoAreaId,
    required int visibleCount,
    required int totalCount,
  }) {
    showMapBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => MapFilterSheet(
        activeStatuses: Set<String>.from(statuses),
        activePollutionTypes: Set<String>.from(pollutionTypes),
        geoAreaId: geoAreaId,
        visibleCount: visibleCount,
        totalCount: totalCount,
        allPollutionTypes: reportPollutionTypeCodes,
        onToggleStatus: ref
            .read(mapFilterNotifierProvider.notifier)
            .toggleStatus,
        onTogglePollutionType: ref
            .read(mapFilterNotifierProvider.notifier)
            .togglePollutionType,
        onGeoAreaIdChanged: ref
            .read(mapFilterNotifierProvider.notifier)
            .setGeoAreaId,
        includeArchived: ref.read(mapFilterNotifierProvider).includeArchived,
        onIncludeArchivedChanged: ref
            .read(mapFilterNotifierProvider.notifier)
            .setIncludeArchived,
        onDismiss: () => Navigator.of(context).pop(),
        onResetFilters: () {
          ref
              .read(mapFilterNotifierProvider.notifier)
              .resetFiltersToCurrentSites(
                ref.read(mapSitesNotifierProvider).sites,
              );
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openSearchModal() {
    showMapBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => MapSearchModal(
        onResultTap: (PollutionSite site) async {
          Navigator.of(context).pop();
          final Map<String, LatLng> coords = ref.read(mapSiteCoordinatesProvider);
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

  void _onMapSurfaceReady() {
    if (!mounted || _mapLayoutReady) return;
    _mapLayoutReady = true;
    try {
      final MapCamera cam = _animatedMapController.mapController.camera;
      ref.read(mapCameraNotifierProvider.notifier).setCamera(
            centerLat: cam.center.latitude,
            centerLng: cam.center.longitude,
            zoom: cam.zoom,
          );
    } catch (_) {
      // Camera not ready yet; clustering will sync on next stable map event.
    }
    _tileOverlaySoftDismissTimer?.cancel();
    _tileOverlaySoftDismissTimer = Timer(
      const Duration(milliseconds: 2600),
      _dismissTileLoadingOverlay,
    );
    _tileOverlayMaxTimer?.cancel();
    _tileOverlayMaxTimer = Timer(
      const Duration(seconds: 14),
      _dismissTileLoadingOverlay,
    );
  }

  void _dismissTileLoadingOverlay() {
    if (!_showTileLoadingOverlay || !mounted) return;
    _tileOverlaySoftDismissTimer?.cancel();
    _tileOverlayMaxTimer?.cancel();
    setState(() => _showTileLoadingOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MapSitesState>(mapSitesNotifierProvider, (
      MapSitesState? previous,
      MapSitesState next,
    ) {
      if (!context.mounted) {
        return;
      }
      if (previous?.syncNotice != null &&
          next.syncNotice == null &&
          next.loadError == null &&
          next.sites.isNotEmpty) {
        AppSnack.show(
          context,
          message: context.l10n.mapUpdatedToast,
          type: AppSnackType.success,
        );
      }
    });
    ref.listen<List<PollutionSite>>(mapFilteredSitesProvider, (
      List<PollutionSite>? previous,
      List<PollutionSite> next,
    ) {
      if (!context.mounted || previous == null) {
        return;
      }
      if (previous.length == next.length) {
        return;
      }
      if (!MediaQuery.supportsAnnounceOf(context)) {
        return;
      }
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.l10n.mapFilteredSitesAnnounce(next.length),
        Directionality.of(context),
      );
    });
    ref.listen<String?>(
      mapFilterNotifierProvider.select((MapFilterState s) => s.geoAreaId),
      (String? previous, String? next) {
        if (!context.mounted) {
          return;
        }
        if (previous == next) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          unawaited(_fitCameraToGeoFilter(next));
        });
      },
    );
    ref.listen<int>(
      mapFilterNotifierProvider.select(MapFilterState.expansionResetKey),
      (int? previous, int next) {
        if (previous != null && previous != next) {
          ref.read(mapClusterExpansionNotifierProvider.notifier).reset();
        }
      },
    );

    final AppError? sitesLoadError = ref.watch(
      mapSitesNotifierProvider.select((MapSitesState s) => s.loadError),
    );
    final MapSyncInlineNotice? sitesSyncNotice = ref.watch(
      mapSitesNotifierProvider.select((MapSitesState s) => s.syncNotice),
    );
    final List<PollutionSite> allSites = ref.watch(
      mapSitesNotifierProvider.select((MapSitesState s) => s.sites),
    );
    final List<PollutionSite> filteredSites = ref.watch(
      mapFilteredSitesProvider.select((List<PollutionSite> s) => s),
    );
    final Map<String, LatLng> coords = ref.watch(
      mapSiteCoordinatesProvider.select((Map<String, LatLng> s) => s),
    );
    final MapFilterState filters = ref.watch(
      mapFilterNotifierProvider.select((MapFilterState s) => s),
    );
    final MapSelectionState selection = ref.watch(
      mapSelectionNotifierProvider.select((MapSelectionState s) => s),
    );
    final MapUiModeState uiMode = ref.watch(
      mapUiModeNotifierProvider.select((MapUiModeState s) => s),
    );
    final MapLocationState location = ref.watch(
      mapLocationNotifierProvider.select((MapLocationState s) => s),
    );
    final MapCameraState camera = ref.watch(
      mapCameraNotifierProvider.select((MapCameraState s) => s),
    );
    final MapClusterExpansionState clusterExpansion = ref.watch(
      mapClusterExpansionNotifierProvider
          .select((MapClusterExpansionState s) => s),
    );
    final List<ClusterBucket> clusters = ref.watch(mapClustersProvider).when(
          skipLoadingOnReload: true,
          data: (List<ClusterBucket> value) => value,
          error: (Object _, StackTrace _) => const <ClusterBucket>[],
          loading: () => const <ClusterBucket>[],
        );

    final bool reduceMapAnimations =
        MediaQuery.of(context).disableAnimations ||
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations ||
        filteredSites.length > 140;
    final List<Polygon> regionFence = buildRegionFence(
      geoAreaId: filters.geoAreaId,
      reduceMotion: reduceMapAnimations,
      boundariesRepository: _boundariesRepository,
    );

    final String nextPartitionSig =
        MapMarkerEntranceCache.clusterPartitionSignature(clusters);
    final String sitesPrefetchSig = allSites.isEmpty
        ? ''
        : allSites.map((PollutionSite s) => s.id).join('\x1e');
    final String clusterEntranceSig =
        '$nextPartitionSig|$reduceMapAnimations|${clusters.length}';
    if (_lastMapSitesPrefetchSig != sitesPrefetchSig) {
      _lastMapSitesPrefetchSig = sitesPrefetchSig;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || allSites.isEmpty) {
          return;
        }
        _prefetchMapPinImages(allSites);
      });
    }
    if (_lastClusterEntranceSig != clusterEntranceSig) {
      _lastClusterEntranceSig = clusterEntranceSig;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (!reduceMapAnimations &&
            _clusterPartitionSig != null &&
            _clusterPartitionSig != nextPartitionSig &&
            _prevBucketsForEntrance.isNotEmpty &&
            clusters.isNotEmpty) {
          MapMarkerEntranceCache.instance.applyReclusterEntranceInvalidations(
            previous: _prevBucketsForEntrance,
            current: clusters,
          );
        }
        _clusterPartitionSig = nextPartitionSig;
        _prevBucketsForEntrance = List<ClusterBucket>.from(clusters);
      });
    }

    final AnimatedPollutionMapMarkers markersLayer = AnimatedPollutionMapMarkers(
      clusters: clusters,
      coords: coords,
      selectedSite: selection.selected,
      reduceAnimations: reduceMapAnimations,
      cameraCenter: LatLng(camera.centerLat, camera.centerLng),
      onSiteTap: (PollutionSite site, LatLng center) {
        ref.read(mapSelectionNotifierProvider.notifier).select(site);
        AppHaptics.tap(context);
        _animatedMapController.animateTo(dest: center, zoom: 14.5);
      },
      onSiteLongPress: _openSiteDetail,
      onClusterTap: (ClusterBucket bucket) =>
          _handleClusterTap(bucket, coords),
      expansionOrigin: clusterExpansion.expansionOrigin,
      expandingSiteIds: clusterExpansion.expandingSiteIds,
      expansionGhostCenter: clusterExpansion.ghostCenter,
      expansionGhostColor: clusterExpansion.ghostColor,
      expansionGhostCount: clusterExpansion.ghostCount,
      expansionToken: clusterExpansion.expansionToken,
    );
    final double topPadding = MediaQuery.of(context).padding.top;

    return Semantics(
      namesRoute: true,
      label: context.l10n.mapScreenRouteSemantic,
      child: Stack(
        children: <Widget>[
          MapCanvas(
            mapController: _animatedMapController.mapController,
            useDarkTiles: uiMode.useDarkTiles,
            userLocation: location.userLocation,
            reduceMapAnimations: reduceMapAnimations,
            showHeatmap: uiMode.showHeatmap,
            heatmapLayer: const MapHeatmapLayer(),
            showEmptyFilterOverlay:
                allSites.isNotEmpty &&
                filteredSites.isEmpty &&
                filters.geoAreaId == null,
            onResetFilters: () => ref
                .read(mapFilterNotifierProvider.notifier)
                .resetFiltersToCurrentSites(allSites),
            markersLayer: markersLayer,
            regionFence: regionFence,
            highDpi: MediaQuery.of(context).devicePixelRatio > 1.0,
            options: MapOptions(
              initialCenter: const LatLng(
                ReportGeoFence.centerLat,
                ReportGeoFence.centerLng,
              ),
              initialZoom: MapLayoutTokens.zoomCity,
              minZoom: 1.5,
              maxZoom: 18,
              backgroundColor: uiMode.useDarkTiles
                  ? AppColors.mapDarkPaper
                  : AppColors.mapLightPaper,
              onMapReady: _onMapSurfaceReady,
              // Cluster/pin markers use [HitTestBehavior.opaque] so their tap wins the
              // gesture arena over the map’s double-tap zoom detector on the same tap.
              interactionOptions: InteractionOptions(
                flags:
                    (InteractiveFlag.doubleTapDragZoom |
                        InteractiveFlag.doubleTapZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.flingAnimation |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.scrollWheelZoom) |
                    (uiMode.rotationLocked
                        ? InteractiveFlag.none
                        : InteractiveFlag.rotate),
              ),
              onMapEvent: (MapEvent event) {
                if (_showTileLoadingOverlay &&
                    _mapLayoutReady &&
                    (event is MapEventMoveEnd ||
                        event is MapEventScrollWheelZoom)) {
                  _tileOverlaySoftDismissTimer?.cancel();
                  _tileOverlaySoftDismissTimer = Timer(
                    const Duration(milliseconds: 400),
                    _dismissTileLoadingOverlay,
                  );
                }
                if (event is MapEventMove) {
                  // Dismiss pin preview on user-initiated gestures (not programmatic animations).
                  if (event.source == MapEventSource.onDrag ||
                      event.source == MapEventSource.onMultiFinger) {
                    final PollutionSite? sel =
                        ref.read(mapSelectionNotifierProvider).selected;
                    if (sel != null) {
                      ref
                          .read(mapSelectionNotifierProvider.notifier)
                          .deselect();
                    }
                  }
                  _viewportMoveEndMicroDebounce?.cancel();
                  _viewportMoveEndMicroDebounce = null;
                  _viewportMoveDebounce?.cancel();
                  _viewportMoveDebounce = Timer(
                    const Duration(milliseconds: 500),
                    () {
                      if (mounted) _syncMapViewport(immediate: false);
                    },
                  );
                }
                if (event is MapEventMoveEnd) {
                  _viewportMoveDebounce?.cancel();
                  _viewportMoveDebounce = null;
                  _viewportMoveEndMicroDebounce?.cancel();
                  _viewportMoveEndMicroDebounce = Timer(
                    const Duration(milliseconds: 150),
                    () {
                      if (!mounted) {
                        return;
                      }
                      try {
                        final MapCamera cam =
                            _animatedMapController.mapController.camera;
                        ref
                            .read(mapSitesNotifierProvider.notifier)
                            .recordPanGestureEnd(
                              centerLat: cam.center.latitude,
                              centerLng: cam.center.longitude,
                              zoom: cam.zoom,
                            );
                      } catch (_) {
                        // Camera may not be ready on first frame.
                      }
                      _syncMapViewport(immediate: false);
                    },
                  );
                }

                final bool inertiaOrZoomEnded =
                    event is MapEventFlingAnimationEnd ||
                    event is MapEventDoubleTapZoomEnd ||
                    event is MapEventRotateEnd;
                if (inertiaOrZoomEnded) {
                  _viewportMoveDebounce?.cancel();
                  _viewportMoveEndMicroDebounce?.cancel();
                  _viewportMoveEndMicroDebounce = Timer(
                    const Duration(milliseconds: 120),
                    () {
                      if (mounted) {
                        _syncMapViewport(immediate: false);
                      }
                    },
                  );
                }

                _maybeUpdateMapCameraNotifierForClustering(event);
                if (_mapRotationNotifier.value != event.camera.rotation) {
                  _mapRotationNotifier.value = event.camera.rotation;
                }
              },
              onTap: (_, _) =>
                  ref.read(mapSelectionNotifierProvider.notifier).deselect(),
            ),
          ),
          TopVignette(
            topPadding: topPadding,
            useDarkTiles: uiMode.useDarkTiles,
          ),
          BottomVignette(useDarkTiles: uiMode.useDarkTiles),
          if (_showTileLoadingOverlay)
            TileLoadingOverlay(
              showLoading: _showTileLoadingOverlay,
              isDarkMap: uiMode.useDarkTiles,
              topPadding: topPadding,
            ),
          if (sitesLoadError != null && allSites.isEmpty)
            MapErrorOverlay(
              loadError: sitesLoadError!,
              onRetry: () => _syncMapViewport(immediate: true),
              retryFootnote: sitesLoadError!.retryable
                  ? context.l10n.mapErrorAutoRetryFootnote
                  : null,
            ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: topPadding + AppSpacing.sm,
            child: FadeTransition(
              opacity: _legendOpacity,
              child: SlideTransition(
                position: _legendSlide,
                child: ValueListenableBuilder<double>(
                  valueListenable: _mapRotationNotifier,
                  builder: (context, rotation, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        MapToolbar(
                          visibleCount: filteredSites.length,
                          rotationLocked: uiMode.rotationLocked,
                          rotationDegrees: rotation,
                          onOpenFilters: () => _openFilterModal(
                            statuses: filters.activeStatuses,
                            pollutionTypes: filters.activePollutionTypes,
                            geoAreaId: filters.geoAreaId,
                            visibleCount: filteredSites.length,
                            totalCount: allSites.length,
                          ),
                          onOpenSearch: () =>
                              _openSearchModal(),
                          onResetRotation: () =>
                              _animatedMapController.animatedRotateReset(),
                        ),
                        if (sitesSyncNotice != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          MapSyncNoticeBanner(
                            notice: sitesSyncNotice!,
                            useDarkTiles: uiMode.useDarkTiles,
                            onTapSync: () => _syncMapViewport(immediate: true),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: MapActionsMenu(
              showHeatmap: uiMode.showHeatmap,
              useDarkTiles: uiMode.useDarkTiles,
              isLocating: location.isLocating,
              locationJustFound: location.locationJustFound,
              rotationLocked: uiMode.rotationLocked,
              onToggleHeatmap: () =>
                  ref.read(mapUiModeNotifierProvider.notifier).toggleHeatmap(),
              onToggleDarkTiles: () => ref
                  .read(mapUiModeNotifierProvider.notifier)
                  .toggleDarkTiles(),
              onZoomToFit: () => _animatedMapController.animatedFitCamera(
                cameraFit: CameraFit.bounds(
                  bounds: _macedoniaBounds,
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  maxZoom: 8,
                  minZoom: 6,
                ),
              ),
              onToggleRotationLock: () {
                final bool next = !uiMode.rotationLocked;
                ref
                    .read(mapUiModeNotifierProvider.notifier)
                    .setRotationLocked(next);
                if (next) _animatedMapController.animatedRotateReset();
              },
              onLocateMe: _handleLocateMe,
            ),
          ),
          if (selection.selected != null)
            MapSitePreviewPositioned(
              site: selection.selected!,
              userLocation: location.userLocation,
              coords: coords,
              useDarkTiles: uiMode.useDarkTiles,
              onGetDirections: (site) => _openDirectionsForSite(site, coords),
              onViewDetails: () => _openSiteDetail(selection.selected!),
              onDismiss: () =>
                  ref.read(mapSelectionNotifierProvider.notifier).deselect(),
            ),
        ],
      ),
    );
  }
}
