import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/utils/cached_tile_provider.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_actions_menu.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/search_modal.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_filter_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/site_preview_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/pollution_markers.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_overlays.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/directions_sheet.dart';

class PollutionMapScreen extends StatefulWidget {
  const PollutionMapScreen({
    super.key,
    this.pendingSiteFocus,
    this.onPendingSiteFocusConsumed,
  });

  final ValueNotifier<String?>? pendingSiteFocus;
  final VoidCallback? onPendingSiteFocusConsumed;

  @override
  State<PollutionMapScreen> createState() => _PollutionMapScreenState();
}

class _PollutionMapScreenState extends State<PollutionMapScreen>
    with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController =
      AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    curve: Curves.easeOutCubic,
  );

  List<PollutionSite> _allSites = <PollutionSite>[];
  Set<String> _activeStatuses = <String>{};
  AppError? _loadError;
  Set<String> _activePollutionTypes = <String>{};
  PollutionSite? _selectedSite;
  LatLng? _userLocation;
  bool _isLocating = false;
  bool _locationJustFound = false;
  final ValueNotifier<double> _mapRotationNotifier = ValueNotifier<double>(0);
  bool _rotationLocked = false;
  bool _useDarkTiles = false;
  bool _showHeatmap = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _legendOpacity = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
  );
  late final Animation<Offset> _legendSlide = Tween<Offset>(
    begin: const Offset(0, -0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
  ));

  /// Center of Macedonia (geographic center) and bounds for country view.
  static final LatLngBounds _macedoniaBounds = LatLngBounds(
    LatLng(ReportGeoFence.minLat, ReportGeoFence.minLng),
    LatLng(ReportGeoFence.maxLat, ReportGeoFence.maxLng),
  );
  static const double _zoomCity = 11.0;

  /// Minimum zoom when expanding a cluster so pins stay visible (don't re-cluster).
  /// At z=15, pixel-radius threshold ≈ 0.0022°, separating Skopje's closest pair (~0.003°).
  static const double _minZoomClusterExpand = 15.0;

  Map<String, LatLng> _siteCoordinates = <String, LatLng>{};

  /// Whether we've already tried to zoom to user location on startup.
  bool _hasAttemptedInitialLocate = false;

  /// Whether to show the tile loading skeleton overlay.
  bool _showTileLoadingOverlay = true;

  bool _pendingFocusBusy = false;

  LatLng? _getSiteCoordinates(String id) => _siteCoordinates[id];

  @override
  void initState() {
    super.initState();
    _activePollutionTypes = _canonicalPollutionTypes.toSet();
    widget.pendingSiteFocus?.addListener(_onPendingSiteFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tryInitialLocate();
        _tryApplyPendingSiteFocus();
      }
    });
    _loadSites();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showTileLoadingOverlay = false);
    });
  }

  void _onPendingSiteFocusChanged() {
    if (widget.pendingSiteFocus?.value != null) {
      _tryApplyPendingSiteFocus();
    }
  }

  Future<void> _tryApplyPendingSiteFocus() async {
    if (_pendingFocusBusy) return;
    final ValueNotifier<String?>? notifier = widget.pendingSiteFocus;
    if (notifier == null || notifier.value == null || !mounted) return;
    _pendingFocusBusy = true;
    final String id = notifier.value!;
    try {
      PollutionSite? local;
      for (final PollutionSite s in _allSites) {
        if (s.id == id) {
          local = s;
          break;
        }
      }
      if (local != null) {
        final LatLng? point = _getSiteCoordinates(local.id);
        if (point != null) {
          _handleSelectSite(local, point);
          if (notifier.value == id) notifier.value = null;
          widget.onPendingSiteFocusConsumed?.call();
          return;
        }
      }

      try {
        final PollutionSite? fetched =
            await ServiceLocator.instance.sitesRepository.getSiteById(id);
        if (!mounted) return;
        if (notifier.value != id) return;
        if (fetched != null &&
            fetched.latitude != null &&
            fetched.longitude != null) {
          final LatLng point =
              LatLng(fetched.latitude!, fetched.longitude!);
          if (!mounted) return;
          setState(() {
            final bool has =
                _allSites.any((PollutionSite s) => s.id == fetched.id);
            if (!has) {
              _allSites = <PollutionSite>[..._allSites, fetched];
              _siteCoordinates = Map<String, LatLng>.from(_siteCoordinates)
                ..[fetched.id] = point;
              _filteredSitesCache = null;
              _filteredSitesCacheHash = 0;
              _displayedSitesCache = null;
              _displayedSitesFilterHashCache = -1;
            }
          });
          final PollutionSite target =
              _allSites.firstWhere((PollutionSite s) => s.id == id);
          _handleSelectSite(target, point);
        } else if (mounted) {
          AppSnack.show(
            context,
            message: 'This site is not available on the map yet.',
            type: AppSnackType.warning,
          );
        }
      } catch (_) {
        if (mounted) {
          AppSnack.show(
            context,
            message: 'Could not open this location on the map.',
            type: AppSnackType.warning,
          );
        }
      }

      if (notifier.value == id) {
        notifier.value = null;
      }
      widget.onPendingSiteFocusConsumed?.call();
    } finally {
      _pendingFocusBusy = false;
    }
  }

  Future<void> _loadSites() async {
    setState(() => _loadError = null);
    try {
      final double lat = _userLocation?.latitude ?? ReportGeoFence.centerLat;
      final double lng = _userLocation?.longitude ?? ReportGeoFence.centerLng;
      final result = await ServiceLocator.instance.sitesRepository.getSites(
        latitude: lat,
        longitude: lng,
        radiusKm: 50,
        page: 1,
        limit: 100,
      );
      if (!mounted) return;
      final Map<String, LatLng> coords = <String, LatLng>{};
      for (final PollutionSite s in result.sites) {
        if (s.latitude != null && s.longitude != null) {
          coords[s.id] = LatLng(s.latitude!, s.longitude!);
        }
      }
      setState(() {
        _allSites = result.sites;
        _siteCoordinates = coords;
        _activeStatuses = result.sites.map((PollutionSite s) => s.statusLabel).toSet();
        _loadError = null;
        _filteredSitesCache = null;
        _filteredSitesCacheHash = 0;
        _displayedSitesCache = null;
        _displayedSitesFilterHashCache = -1;
      });
      _tryApplyPendingSiteFocus();
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
      if (mounted) {
        AppSnack.show(context, message: e.message, type: AppSnackType.warning);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = AppError.network(cause: e));
      if (mounted) {
        AppSnack.show(
          context,
          message: 'No connection',
          type: AppSnackType.warning,
        );
      }
    }
  }

  /// Best practice: try to start at user's city when possible; otherwise show whole country.
  Future<void> _tryInitialLocate() async {
    if (_hasAttemptedInitialLocate) return;
    _hasAttemptedInitialLocate = true;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      if (!mounted) return;
      final LatLng location = LatLng(pos.latitude, pos.longitude);
      setState(() => _userLocation = location);

      await _animatedMapController.animateTo(
        dest: location,
        zoom: _zoomCity,
      );
    } catch (_) {
      // Fallback: stay at country view (initialZoom)
    }
  }

  void _onSearchResultTap(PollutionSite site) {
    final LatLng? point = _getSiteCoordinates(site.id);
    if (point == null) return;
    setState(() {
      _selectedSite = site;
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
    AppHaptics.pinSelect();
    _animatedMapController.animateTo(
      dest: point,
      zoom: 14.5.clamp(3, 18).toDouble(),
    );
  }

  @override
  void didUpdateWidget(PollutionMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pendingSiteFocus != widget.pendingSiteFocus) {
      oldWidget.pendingSiteFocus?.removeListener(_onPendingSiteFocusChanged);
      widget.pendingSiteFocus?.addListener(_onPendingSiteFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.pendingSiteFocus?.removeListener(_onPendingSiteFocusChanged);
    _mapRotationNotifier.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _entranceController.dispose();
    _animatedMapController.dispose();
    super.dispose();
  }

  /// Canonical pollution types from reporting flow (ReportCategory labels).
  List<String> get _canonicalPollutionTypes => reportPollutionTypeLabels;

  List<PollutionSite>? _filteredSitesCache;
  int _filteredSitesCacheHash = 0;

  List<PollutionSite> get _filteredSites {
    final int hash = Object.hash(
      Object.hashAll(_activeStatuses),
      Object.hashAll(_activePollutionTypes),
    );
    if (_filteredSitesCache != null && _filteredSitesCacheHash == hash) {
      return _filteredSitesCache!;
    }
    _filteredSitesCacheHash = hash;
    _filteredSitesCache = _allSites.where((PollutionSite s) {
      if (!_activeStatuses.contains(s.statusLabel)) return false;
      final String? pt = s.pollutionType;
      if (pt == null) return true;
      return _activePollutionTypes.contains(pt);
    }).toList();
    return _filteredSitesCache!;
  }

  List<PollutionSite>? _displayedSitesCache;
  String _displayedSitesQueryCache = '';
  int _displayedSitesFilterHashCache = 0;
  int _displayedSitesCacheHash = 0;

  List<PollutionSite> get _displayedSites {
    final String q = _searchController.text.trim();
    final int filterHash = _filteredSitesCacheHash;
    if (_displayedSitesCache != null &&
        _displayedSitesQueryCache == q &&
        _displayedSitesFilterHashCache == filterHash) {
      return _displayedSitesCache!;
    }
    _displayedSitesQueryCache = q;
    _displayedSitesFilterHashCache = filterHash;
    if (q.isEmpty) {
      _displayedSitesCache = _filteredSites;
    } else {
      final String qLower = q.toLowerCase();
      _displayedSitesCache = _filteredSites
          .where(
              (PollutionSite s) => s.title.toLowerCase().contains(qLower))
          .toList();
    }
    _displayedSitesCacheHash = Object.hashAll(
        _displayedSitesCache!.map((PollutionSite s) => s.id));
    return _displayedSitesCache!;
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_activeStatuses.contains(status)) {
        if (_activeStatuses.length == 1) return;
        _activeStatuses.remove(status);
      } else {
        _activeStatuses.add(status);
      }
    });
    AppHaptics.light();
  }

  void _togglePollutionType(String type) {
    setState(() {
      if (_activePollutionTypes.contains(type)) {
        if (_activePollutionTypes.length == 1) return;
        _activePollutionTypes.remove(type);
      } else {
        _activePollutionTypes.add(type);
      }
    });
    AppHaptics.light();
  }

  void _openSearchModal() {
    AppHaptics.light();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => MapSearchModal(
        allSites: _filteredSites,
        onResultTap: (PollutionSite site) {
          Navigator.of(context).pop();
          _onSearchResultTap(site);
        },
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _openFilterModal() {
    AppHaptics.light();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => MapFilterSheet(
        activeStatuses: Set<String>.from(_activeStatuses),
        activePollutionTypes: Set<String>.from(_activePollutionTypes),
        visibleCount: _filteredSites.length,
        totalCount: _allSites.length,
        allPollutionTypes: _canonicalPollutionTypes,
        onToggleStatus: _toggleStatus,
        onTogglePollutionType: _togglePollutionType,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _toggleRotationLock() {
    setState(() {
      _rotationLocked = !_rotationLocked;
      if (_rotationLocked) {
        _animatedMapController.animatedRotateReset();
      }
    });
    AppHaptics.light();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Semantics(
      label: 'Pollution map. Tap pins to view site details.',
      child: Stack(
        children: <Widget>[
          _buildMap(),

        TopVignette(topPadding: topPadding),
        const BottomVignette(),
        if (_showTileLoadingOverlay)
          TileLoadingOverlay(showLoading: _showTileLoadingOverlay),
        if (_loadError != null)
          Positioned.fill(
            child: Container(
              color: AppColors.panelBackground,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: AppErrorView(
                  error: _loadError!,
                  onRetry: _loadSites,
                ),
              ),
            ),
          ),
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: MapActionsMenu(
            showHeatmap: _showHeatmap,
            useDarkTiles: _useDarkTiles,
            isLocating: _isLocating,
            locationJustFound: _locationJustFound,
            rotationLocked: _rotationLocked,
            onToggleHeatmap: () {
              setState(() => _showHeatmap = !_showHeatmap);
              AppHaptics.light();
            },
            onToggleDarkTiles: () {
              setState(() => _useDarkTiles = !_useDarkTiles);
              AppHaptics.light();
            },
            onZoomToFit: _handleZoomToFitAll,
            onToggleRotationLock: _toggleRotationLock,
            onLocateMe: _handleLocateMe,
            onRefresh: _loadSites,
          ),
        ),

        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: topPadding + AppSpacing.sm,
          child: FadeTransition(
            opacity: _legendOpacity,
            child: SlideTransition(
              position: _legendSlide,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MapFilterButton(
                    visibleCount: _displayedSites.length,
                    hasFilterActive: _activeStatuses.length < 3 ||
                        _activePollutionTypes.length < _canonicalPollutionTypes.length,
                    onTap: _openFilterModal,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      MapSearchIconButton(
                        onTap: () => _openSearchModal(),
                      ),
                      if (!_rotationLocked) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ValueListenableBuilder<double>(
                          valueListenable: _mapRotationNotifier,
                          builder: (BuildContext context, double rotation, _) {
                            return MapCompassButton(
                              rotationDegrees: rotation,
                              onReset: () {
                                AppHaptics.settle();
                                _animatedMapController.animatedRotateReset();
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: null,
          bottom: AppSpacing.lg + 72,
          height: 240,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final Animation<double> scale = Tween<double>(begin: 0.96, end: 1)
                  .animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ));
              final Animation<double> opacity = CurvedAnimation(
                parent: animation,
                curve: const Interval(0, 0.8, curve: Curves.easeOut),
              );
              return ScaleTransition(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  ...previousChildren.map(
                    (Widget w) => Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: w,
                      ),
                    ),
                  ),
                  if (currentChild != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: currentChild,
                      ),
                    ),
                ],
              );
            },
            child: _selectedSite == null
                ? const SizedBox.shrink(key: ValueKey<String>('empty'))
                : SitePreviewSheet(
                    key: ValueKey<String>(_selectedSite!.id),
                    site: _selectedSite!,
                    userLocation: _userLocation,
                    siteCoordinates: _siteCoordinates,
                    onGetDirections: _openDirectionsForSite,
                    onViewDetails: () => _openSiteDetail(_selectedSite!),
                    onDismiss: () {
                      setState(() => _selectedSite = null);
                      AppHaptics.sheetDismiss();
                    },
                  ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _animatedMapController.mapController,
      options: MapOptions(
        initialCenter: LatLng(ReportGeoFence.centerLat, ReportGeoFence.centerLng),
        initialZoom: _zoomCity,
        minZoom: 1.5,
        maxZoom: 18,
        interactionOptions: InteractionOptions(
          flags: (InteractiveFlag.doubleTapDragZoom |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.flingAnimation |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.scrollWheelZoom) |
              (_rotationLocked ? InteractiveFlag.none : InteractiveFlag.rotate),
        ),
        onMapEvent: (MapEvent event) {
          if (event is MapEventDoubleTapZoom) {
            AppHaptics.tap();
          }
          final double rot = event.camera.rotation;
          if (_mapRotationNotifier.value != rot) {
            _mapRotationNotifier.value = rot;
          }
        },
        onTap: (TapPosition pos, LatLng point) {
          if (_selectedSite != null) {
            setState(() => _selectedSite = null);
            AppHaptics.pinDeselect();
          }
        },
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: _useDarkTiles
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const <String>['a', 'b', 'c', 'd'],
          maxNativeZoom: 20,
          userAgentPackageName: 'chisto_mobile',
          retinaMode: false,
          tileProvider: createCachedTileProvider(maxStaleDays: 30),
          tileDisplay: TileDisplay.instantaneous(),
        ),
        if (_userLocation != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: _userLocation!,
                width: 80,
                height: 80,
                child: UserLocationDot(key: ValueKey<LatLng>(_userLocation!)),
              ),
            ],
          ),
        if (_showHeatmap) _buildHeatmapLayer(),
        if (_allSites.isNotEmpty && _displayedSites.isEmpty)
          EmptyFilterOverlay(
            onResetFilters: () {
              setState(() {
                _activeStatuses = _allSites
                    .map((PollutionSite s) => s.statusLabel)
                    .toSet();
                _activePollutionTypes = _canonicalPollutionTypes.toSet();
                _searchController.clear();
              });
              AppHaptics.light();
            },
          ),
        Builder(
          builder: (BuildContext context) {
            final MapCamera? camera = MapCamera.maybeOf(context);
            if (camera == null) return const SizedBox.shrink();
            return MarkerLayer(markers: _buildClusteredMarkers(camera));
          },
        ),
      ],
    );
  }

  List<WeightedLatLng>? _heatmapDataCache;
  int _heatmapDataCacheKey = 0;

  Widget _buildHeatmapLayer() {
    final int key = _displayedSitesCacheHash;
    if (_heatmapDataCache == null || _heatmapDataCacheKey != key) {
      _heatmapDataCacheKey = key;
      final List<WeightedLatLng> data = <WeightedLatLng>[];
      for (final PollutionSite site in _displayedSites) {
        final LatLng? point = _getSiteCoordinates(site.id);
        if (point == null) continue;
        final double weight = site.statusLabel == 'High'
            ? 3.0
            : site.statusLabel == 'Medium'
                ? 2.0
                : 1.0;
        data.add(WeightedLatLng(point, weight));
      }
      _heatmapDataCache = data;
    }
    final List<WeightedLatLng> data = _heatmapDataCache!;
    if (data.isEmpty) return const SizedBox.shrink();
    return HeatMapLayer(
      heatMapDataSource: InMemoryHeatMapDataSource(data: data),
      heatMapOptions: HeatMapOptions(
        gradient: HeatMapOptions.defaultGradient,
        minOpacity: 0.2,
        radius: 25,
      ),
    );
  }

  int _entranceDelayMsForPoint(LatLng point, MapCamera camera) {
    final LatLng center = camera.center;
    final double dLat = (point.latitude - center.latitude).abs();
    final double dLng = (point.longitude - center.longitude).abs();
    final double distance = math.sqrt(dLat * dLat + dLng * dLng);
    const double maxDistance = 0.035;
    final int delayMs =
        (distance / maxDistance * 320).round().clamp(0, 380);
    return delayMs;
  }

  /// Expands the map to show all sites in a cluster. When the cluster spans a
  /// large area (zoomed-out view), we avoid forcing minZoom so the fit shows
  /// all sites. For tight clusters, we zoom in enough to prevent re-clustering.
  void _expandClusterToShowSites(List<LatLng> points) {
    if (points.isEmpty) return;
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
    final LatLng southWest = LatLng(
      minLat - padLat / 2,
      minLng - padLng / 2,
    );
    final LatLng northEast = LatLng(
      maxLat + padLat / 2,
      maxLng + padLng / 2,
    );
    final double spanDeg =
        math.sqrt(spanLat * spanLat + spanLng * spanLng);
    final bool isTightCluster = spanDeg < 0.03;
    final LatLngBounds bounds = LatLngBounds(southWest, northEast);
    _animatedMapController.animatedFitCamera(
      cameraFit: CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(AppSpacing.xxl + AppSpacing.lg),
        maxZoom: 18,
        minZoom: isTightCluster ? _minZoomClusterExpand : 6,
      ),
    );
  }

  /// Pixel-radius threshold — same approach as Google Maps, Mapbox, Apple Maps.
  /// A fixed pixel radius is converted to degrees, so clustering is consistent
  /// at every zoom level and on every screen size.
  /// threshold° = pixelRadius × 360 / (2^zoom × 256)
  double _clusterThresholdForZoom(double zoom) {
    const double pixelRadius = 50;
    return pixelRadius * 360 / (math.pow(2, zoom.clamp(1, 20)) * 256);
  }

  List<Marker> _buildClusteredMarkers(MapCamera camera) {
    final double threshold = _clusterThresholdForZoom(camera.zoom);
    final String? selectedId = _selectedSite?.id;

    final List<ClusterBucket> buckets = <ClusterBucket>[];

    for (final PollutionSite site in _displayedSites) {
      final LatLng? point = _getSiteCoordinates(site.id);
      if (point == null) continue;

      if (site.id == selectedId) {
        buckets.add(ClusterBucket(center: point, sites: <PollutionSite>[site]));
        continue;
      }

      ClusterBucket? target;
      for (final ClusterBucket b in buckets) {
        if (b.sites.any((PollutionSite s) => s.id == selectedId)) continue;
        for (final PollutionSite s in b.sites) {
          final LatLng? bp = _getSiteCoordinates(s.id);
          if (bp == null) continue;
          final double dLat = (point.latitude - bp.latitude).abs();
          final double dLng = (point.longitude - bp.longitude).abs();
          if (dLat <= threshold && dLng <= threshold) {
            target = b;
            break;
          }
        }
        if (target != null) break;
      }

      if (target == null) {
        buckets.add(ClusterBucket(center: point, sites: <PollutionSite>[site]));
      } else {
        target.addSite(site, point);
      }
    }

    final List<Marker> markers = <Marker>[];

    for (final ClusterBucket bucket in buckets) {
      final Duration entranceDelay =
          Duration(milliseconds: _entranceDelayMsForPoint(bucket.center, camera));

      if (bucket.sites.length == 1) {
        final PollutionSite site = bucket.sites.first;
        final bool selected = _selectedSite?.id == site.id;
        final double pinSize = selected ? 64 : 52;
        markers.add(Marker(
          point: bucket.center,
          width: pinSize,
          height: pinSize,
          child: PollutionMarker(
            site: site,
            isSelected: selected,
            entranceDelay: entranceDelay,
            onTap: () => _handleSelectSite(site, bucket.center),
          ),
        ));
      } else {
        final int count = bucket.sites.length;
        final double size = (36 + 8 * math.sqrt(count)).clamp(38, 64);
        markers.add(Marker(
          point: bucket.center,
          width: size,
          height: size,
          child: ClusterMarker(
            count: count,
            bucket: bucket,
            entranceDelay: entranceDelay,
            onTap: () {
              AppHaptics.clusterExpand();
              final List<LatLng> points = bucket.sites
                  .map((PollutionSite s) => _getSiteCoordinates(s.id))
                  .whereType<LatLng>()
                  .toList();
              if (points.isEmpty) return;
              if (points.length == 1) {
                _animatedMapController.animateTo(
                  dest: points.first,
                  zoom: (camera.zoom + 2).clamp(3, 18).toDouble(),
                );
              } else {
                _expandClusterToShowSites(points);
              }
            },
          ),
        ));
      }
    }

    return markers;
  }

  Future<void> _openSiteDetail(PollutionSite site) async {
    AppHaptics.softTransition();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PollutionSiteDetailScreen(site: site),
      ),
    );
  }

  Future<void> _handleLocateMe() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _locationJustFound = false;
    });
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppHaptics.gpsFailed();
        if (mounted) setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppHaptics.gpsFailed();
        if (mounted) setState(() => _isLocating = false);
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );

      final LatLng location = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      setState(() {
        _userLocation = location;
        _isLocating = false;
        _locationJustFound = true;
      });

      AppHaptics.gpsFound();
      await _animatedMapController.animateTo(
        dest: location,
        zoom: 16.5.clamp(3, 18).toDouble(),
      );

      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _locationJustFound = false);
    } catch (_) {
      if (!mounted) return;
      AppHaptics.gpsFailed();
      setState(() => _isLocating = false);
    }
  }

  void _handleSelectSite(PollutionSite site, LatLng point) {
    setState(() => _selectedSite = site);
    AppHaptics.pinSelect();
    _animatedMapController.animateTo(
      dest: point,
      zoom: 14.5.clamp(3, 18).toDouble(),
    );
  }

  void _openDirectionsForSite(PollutionSite site) {
    final LatLng? point = _getSiteCoordinates(site.id);
    if (point == null) return;
    AppHaptics.light();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DirectionsSheet(
          onAppleMapsTap: () {
            AppHaptics.light();
            Navigator.of(context).pop();
            _launchDirections(site, useAppleMaps: true);
          },
          onGoogleMapsTap: () {
            AppHaptics.light();
            Navigator.of(context).pop();
            _launchDirections(site, useAppleMaps: false);
          },
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  Future<void> _launchDirections(PollutionSite site, {required bool useAppleMaps}) async {
    final LatLng? point = _getSiteCoordinates(site.id);
    if (point == null) return;
    final LatLng? origin = _userLocation;
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
      } else {
        if (mounted) _showDirectionsError();
      }
    } catch (_) {
      if (mounted) _showDirectionsError();
    }
  }

  void _showDirectionsError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not open Maps'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleZoomToFitAll() {
    AppHaptics.light();
    _animatedMapController.animatedFitCamera(
      cameraFit: CameraFit.bounds(
        bounds: _macedoniaBounds,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        maxZoom: 8,
        minZoom: 6,
      ),
    );
  }
}

