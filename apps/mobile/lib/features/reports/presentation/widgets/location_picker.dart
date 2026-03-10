import 'dart:async';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerResult {
  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.isInMacedonia = true,
    this.fromUser = true,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final bool isInMacedonia;
  final bool fromUser;
}

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationChanged,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final void Function(LocationPickerResult result) onLocationChanged;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final MapController _mapController = MapController();
  String? _address;
  bool _resolvingGps = false;
  bool _permissionUnavailable = false;
  bool _locationLookupFailed = false;
  Timer? _geocodeDebounce;
  LatLng? _currentCenter;
  LatLng? _confirmedCenter;
  double _currentZoom = 7;
  bool _gpsOutsideCoverage = false;
  bool _gpsNeedsReview = false;
  bool _needsConfirmation = false;
  int _geocodeRequestId = 0;
  double? _gpsAccuracyMeters;
  LatLng? _lastGeocodedCenter;
  bool _lastGeocodeWasMacedonia = false;
  bool _geocodingInProgress = false;
  bool _wasAtFenceLastMove = false;
  bool _confirmButtonPressed = false;
  int _geocodeRetryCount = 0;
  bool _useLocationButtonPressed = false;
  bool _wasAtMaxZoomLastMove = false;
  /// Distance in degrees from boundary to trigger fence haptic.
  static const double _fenceThreshold = 0.018;

  static final LatLngBounds _macedoniaBounds = LatLngBounds(
    LatLng(ReportGeoFence.minLat, ReportGeoFence.minLng),
    LatLng(ReportGeoFence.maxLat, ReportGeoFence.maxLng),
  );

  static LatLng get _macedoniaCenter =>
      const LatLng(ReportGeoFence.centerLat, ReportGeoFence.centerLng);

  bool _samePoint(LatLng? a, LatLng? b) {
    if (a == null || b == null) return false;
    return (a.latitude - b.latitude).abs() < 0.0001 &&
        (a.longitude - b.longitude).abs() < 0.0001;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      final LatLng initial = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _currentCenter = initial;
      _confirmedCenter = initial;
      _currentZoom = 16;
      _lastGeocodedCenter = initial;
      _lastGeocodeWasMacedonia = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _safeMapMove(initial, 16);
        setState(() => _geocodingInProgress = true);
        _reverseGeocode(
          initial,
          fromUser: false,
          autoConfirm: false,
          requestId: ++_geocodeRequestId,
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _detectCurrentLocation();
      });
    }
  }

  void _safeMapMove(LatLng center, double zoom) {
    if (!mounted) return;
    try {
      _mapController.move(center, zoom);
    } catch (_) {
      // Map may not be ready yet; ignore.
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  bool _isAtFence(double lat, double lng) {
    final double dLatMin = lat - ReportGeoFence.minLat;
    final double dLatMax = ReportGeoFence.maxLat - lat;
    final double dLngMin = lng - ReportGeoFence.minLng;
    final double dLngMax = ReportGeoFence.maxLng - lng;
    return dLatMin <= _fenceThreshold ||
        dLatMax <= _fenceThreshold ||
        dLngMin <= _fenceThreshold ||
        dLngMax <= _fenceThreshold;
  }

  bool get _currentPositionIsInMacedoniaByApi =>
      _lastGeocodedCenter != null &&
      _currentCenter != null &&
      _samePoint(_currentCenter, _lastGeocodedCenter) &&
      _lastGeocodeWasMacedonia;

  Future<bool> _ensurePermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<void> _detectCurrentLocation() async {
    if (_resolvingGps) return;
    if (!mounted) return;
    setState(() {
      _resolvingGps = true;
      _permissionUnavailable = false;
      _gpsOutsideCoverage = false;
      _gpsNeedsReview = false;
      _locationLookupFailed = false;
    });

    try {
      final bool ok = await _ensurePermission();
      if (!mounted) return;
      if (!ok) {
        AppHaptics.gpsFailed();
        setState(() {
          _resolvingGps = false;
          _permissionUnavailable = true;
          _gpsOutsideCoverage = false;
        });
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );

      if (!mounted) return;

      if (!ReportGeoFence.contains(pos.latitude, pos.longitude)) {
        AppHaptics.gpsFailed();
        setState(() {
          _resolvingGps = false;
          _gpsOutsideCoverage = true;
          _gpsNeedsReview = false;
          _gpsAccuracyMeters = pos.accuracy;
          _needsConfirmation = false;
        });
        return;
      }

      final LatLng position = LatLng(pos.latitude, pos.longitude);
      final bool needsReview = pos.accuracy > 60;
      if (mounted) {
        setState(() {
          _currentCenter = position;
          // Zoom in tighter when using GPS so users can precisely place the pin.
          _currentZoom = 17.5;
          _needsConfirmation = true;
          _resolvingGps = false;
          _permissionUnavailable = false;
          _gpsOutsideCoverage = false;
          _gpsNeedsReview = needsReview;
          _gpsAccuracyMeters = pos.accuracy;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _safeMapMove(position, 17.5);
      });
      AppHaptics.gpsFound();
      await _reverseGeocode(
        position,
        fromUser: false,
        autoConfirm: false,
        requestId: ++_geocodeRequestId,
      );
    } catch (_) {
      if (mounted) {
        AppHaptics.gpsFailed();
        setState(() {
          _resolvingGps = false;
          _locationLookupFailed = true;
          _gpsNeedsReview = true;
        });
      }
    }
  }

  void _onMapMoved(MapPosition position, bool hasGesture) {
    if (!hasGesture) {
      _wasAtFenceLastMove = false;
      _wasAtMaxZoomLastMove = false;
      return;
    }
    if (position.center == null) return;

    final LatLng newCenter = position.center!;
    final double newZoom = position.zoom ?? _currentZoom;
    _currentZoom = newZoom;

    final bool atFence = _isAtFence(newCenter.latitude, newCenter.longitude);
    if (atFence && !_wasAtFenceLastMove) {
      AppHaptics.boundaryLimitPulse();
    }
    _wasAtFenceLastMove = atFence;

    // Light haptic when the user first hits the maximum zoom level.
    const double kMaxZoom = 19;
    final bool atMaxZoom = newZoom >= kMaxZoom;
    if (atMaxZoom && !_wasAtMaxZoomLastMove) {
      AppHaptics.light();
    }
    _wasAtMaxZoomLastMove = atMaxZoom;

    if (!mounted) return;
    setState(() {
      _currentCenter = newCenter;
      _needsConfirmation = !_samePoint(newCenter, _confirmedCenter);
      _gpsOutsideCoverage = false;
      _gpsNeedsReview = false;
    });
    _geocodeDebounce?.cancel();
    final int requestId = ++_geocodeRequestId;
    setState(() => _geocodingInProgress = true);
    _geocodeDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_currentCenter != null) {
        _reverseGeocode(
          _currentCenter!,
          fromUser: hasGesture,
          requestId: requestId,
        );
      } else if (mounted) {
        setState(() => _geocodingInProgress = false);
      }
    });
  }

  Future<void> _reverseGeocode(
    LatLng position, {
    required bool fromUser,
    bool autoConfirm = false,
    required int requestId,
  }) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted || requestId != _geocodeRequestId) return;
      bool isMacedonia = false;
      bool addressSet = false;
      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        final List<String> parts = <String>[
          p.street ?? '',
          p.locality ?? '',
        ].where((String s) => s.trim().isNotEmpty).toList();
        final String countryName = (p.country ?? '').toLowerCase();
        final String? countryCode = p.isoCountryCode;
        isMacedonia =
            countryCode?.toUpperCase() == 'MK' ||
            countryName.contains('macedonia');
        if (parts.isNotEmpty) {
          addressSet = true;
        }
      }
      final String addressStr = addressSet && placemarks.isNotEmpty
          ? [
              placemarks.first.street ?? '',
              placemarks.first.locality ?? '',
            ].where((String s) => s.trim().isNotEmpty).join(', ')
          : '';
      if (mounted) {
        setState(() {
          _geocodingInProgress = false;
          _lastGeocodedCenter = position;
          _lastGeocodeWasMacedonia = isMacedonia;
          _address = addressStr.isNotEmpty
              ? addressStr
              : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _locationLookupFailed = false;
          _geocodeRetryCount = 0;
          _needsConfirmation =
              isMacedonia && !_samePoint(position, _confirmedCenter);
        });
      }
      if (autoConfirm) {
        _confirmSelection(fromUser: fromUser);
      }
    } catch (_) {
      if (mounted && requestId == _geocodeRequestId) {
        setState(() {
          _geocodingInProgress = false;
          _lastGeocodedCenter = position;
          _lastGeocodeWasMacedonia = false;
          _address =
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _locationLookupFailed = true;
          _needsConfirmation = !_samePoint(position, _confirmedCenter);
        });
      }
      if (autoConfirm) {
        _confirmSelection(fromUser: fromUser);
      }
    }
  }

  Future<void> _retryGeocode() async {
    final LatLng? center = _currentCenter;
    if (center == null || _geocodingInProgress) return;
    AppHaptics.light();
    _geocodeRetryCount += 1;
    final int requestId = ++_geocodeRequestId;
    setState(() => _geocodingInProgress = true);
    await _reverseGeocode(
      center,
      fromUser: false,
      autoConfirm: false,
      requestId: requestId,
    );
  }

  void _confirmSelection({required bool fromUser}) {
    final LatLng? position = _currentCenter;
    if (position == null) return;
    if (!_currentPositionIsInMacedoniaByApi) {
      AppHaptics.locationRejected();
      return;
    }
    setState(() {
      _confirmedCenter = position;
      _needsConfirmation = false;
      _gpsNeedsReview = false;
    });
    AppHaptics.locationConfirmed();
    _notifyParent(position, isInMacedonia: true, fromUser: fromUser);
  }

  void _notifyParent(
    LatLng position, {
    required bool isInMacedonia,
    required bool fromUser,
  }) {
    widget.onLocationChanged(
      LocationPickerResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: _address,
        isInMacedonia: isInMacedonia,
        fromUser: fromUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = _currentCenter ?? _macedoniaCenter;
    final double zoom = _currentCenter != null ? _currentZoom : 7;
    final bool hasConfirmedLocation =
        _confirmedCenter != null &&
        _samePoint(_currentCenter, _confirmedCenter) &&
        !_needsConfirmation;
    final bool apiSaysOutsideMacedonia =
        _lastGeocodedCenter != null &&
        _currentCenter != null &&
        _samePoint(_currentCenter, _lastGeocodedCenter) &&
        !_lastGeocodeWasMacedonia;
    final String stateLabel = _permissionUnavailable
        ? 'Location permission needed'
        : _resolvingGps && _currentCenter == null
        ? 'Detecting your position'
        : _geocodingInProgress
        ? 'Checking location…'
        : _gpsOutsideCoverage
        ? 'Current location unavailable'
        : _gpsNeedsReview
        ? 'Review detected location'
        : apiSaysOutsideMacedonia
        ? 'Location outside Macedonia'
        : _needsConfirmation
        ? 'Pin needs confirmation'
        : hasConfirmedLocation
        ? 'Location confirmed'
        : 'Tap Confirm when ready';

    return Semantics(
      label: 'Location picker. $stateLabel',
      liveRegion: true,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          sortKey: OrdinalSortKey(0),
          label: 'Map. Drag to move the pin. Pin cannot leave Macedonia.',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 240,
              width: double.infinity,
              child: Stack(
                children: <Widget>[
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: zoom,
                      // Prevent over-zooming so satellite tiles don’t become
                      // overly pixelated while still allowing precise placement.
                      maxZoom: 19,
                      cameraConstraint: CameraConstraint.containCenter(
                        bounds: _macedoniaBounds,
                      ),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onPositionChanged:
                          (MapPosition position, bool hasGesture) {
                        _onMapMoved(position, hasGesture);
                      },
                    ),
                    children: <Widget>[
                      TileLayer(
                        // Esri World Imagery – satellite basemap, no API key needed.
                        urlTemplate:
                            'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        maxNativeZoom: 19,
                        userAgentPackageName: 'chisto_mobile',
                      ),
                    ],
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: AnimatedScale(
                      scale: hasConfirmedLocation ? 1.08 : 1.0,
                      duration: AppMotion.medium,
                      curve: AppMotion.emphasized,
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 40,
                        // Keep the green pin, but slightly reduce opacity so
                        // satellite imagery remains clearly visible beneath it.
                        color:
                            AppColors.primaryDark.withValues(alpha: 0.84),
                        shadows: <Shadow>[
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: _buildUseCurrentLocationButton(),
                ),
                if (_resolvingGps && _currentCenter == null)
                  const Positioned.fill(child: _MapTilesFallback()),
              ],
            ),
          ),
        ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildStatusSection(
          stateLabel: stateLabel,
          hasConfirmedLocation: hasConfirmedLocation,
        ),
      ],
    ),
    );
  }

  Widget _buildStatusSection({
    required String stateLabel,
    required bool hasConfirmedLocation,
  }) {
    final bool showConfirmAction =
        _currentCenter != null &&
        (_needsConfirmation || !hasConfirmedLocation) &&
        _currentPositionIsInMacedoniaByApi;

    return Semantics(
      sortKey: OrdinalSortKey(1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            label: stateLabel,
            child: ReportStatePill(
              label: stateLabel,
              tone: hasConfirmedLocation
                  ? ReportSurfaceTone.success
                  : _gpsOutsideCoverage
                  ? ReportSurfaceTone.warning
                  : _lastGeocodedCenter != null &&
                        _currentCenter != null &&
                        _samePoint(_currentCenter, _lastGeocodedCenter) &&
                        !_lastGeocodeWasMacedonia
                  ? ReportSurfaceTone.danger
                  : _needsConfirmation
                  ? ReportSurfaceTone.warning
                  : ReportSurfaceTone.neutral,
              icon: hasConfirmedLocation
                  ? Icons.check_circle_outline
                  : _gpsOutsideCoverage
                  ? Icons.gps_not_fixed_rounded
                  : _lastGeocodedCenter != null &&
                        _currentCenter != null &&
                        _samePoint(_currentCenter, _lastGeocodedCenter) &&
                        !_lastGeocodeWasMacedonia
                  ? Icons.location_off_outlined
                  : Icons.place_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _gpsNeedsReview
              ? 'We found your current location. Review the pin, then confirm.'
              : _lastGeocodedCenter != null &&
                    _currentCenter != null &&
                    _samePoint(_currentCenter, _lastGeocodedCenter) &&
                    !_lastGeocodeWasMacedonia
              ? 'This location is outside Macedonia. Move the pin inside the country.'
              : hasConfirmedLocation
              ? 'The pinned location is ready to submit.'
              : 'Move the pin to the exact spot, then tap Confirm. The map stays inside Macedonia.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_geocodingInProgress || _address != null) ...<Widget>[
            _buildAddressBadge(),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (_locationLookupFailed && _currentCenter != null && !_geocodingInProgress)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Semantics(
                    button: true,
                    label: 'Retry address',
                    hint: 'Double-tap to look up the address again.',
                    child: TextButton.icon(
                    onPressed: _retryGeocode,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry address'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                    ),
                  ),
                ),
                  if (_geocodeRetryCount >= 2)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Address lookup unavailable. You can still confirm the pin.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_needsConfirmation) ...<Widget>[
            ReportInfoBanner(
            title: _gpsNeedsReview
                ? 'Confirm current location'
                : 'Confirm location',
            message: _gpsNeedsReview
                ? _gpsAccuracyMeters != null
                      ? 'About ${_gpsAccuracyMeters!.round()} m accuracy. Adjust the pin if needed, then confirm.'
                      : 'Review the detected spot, adjust if needed, then confirm.'
                : 'Place the pin on the exact site, then tap Confirm.',
            icon: Icons.touch_app_outlined,
              tone: ReportSurfaceTone.warning,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (_permissionUnavailable) ...<Widget>[
            const ReportInfoBanner(
            icon: Icons.location_disabled_outlined,
            tone: ReportSurfaceTone.neutral,
              message: 'Location access is off. Move the map manually, then confirm the pin.',
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (_gpsOutsideCoverage) ...<Widget>[
            const ReportInfoBanner(
            icon: Icons.public_off_outlined,
            tone: ReportSurfaceTone.warning,
            title: 'Current location outside coverage',
              message: 'GPS is outside Macedonia. Move the pin manually or try again.',
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (showConfirmAction)
            Semantics(
            button: true,
            enabled: !_geocodingInProgress,
            label: 'Confirm location. ${hasConfirmedLocation ? "Location already confirmed" : "Set this spot as the report location"}',
            hint: hasConfirmedLocation
                ? 'Location is set for this report.'
                : 'Double-tap to set this spot as the report location.',
            child: GestureDetector(
              onTapDown: _geocodingInProgress
                  ? null
                  : (_) => setState(() => _confirmButtonPressed = true),
              onTapUp: (_) => setState(() => _confirmButtonPressed = false),
              onTapCancel: () => setState(() => _confirmButtonPressed = false),
              behavior: HitTestBehavior.opaque,
              child: AnimatedScale(
                scale: _confirmButtonPressed ? 0.98 : 1.0,
                duration: AppMotion.xFast,
                curve: AppMotion.standardCurve,
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _geocodingInProgress
                        ? null
                        : () {
                            AppHaptics.tap();
                            _confirmSelection(fromUser: true);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _geocodingInProgress
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _geocodingInProgress ? 'Checking…' : 'Confirm location',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBadge() {
    final bool checking = _geocodingInProgress;
    final String displayText = checking
        ? 'Checking address…'
        : _locationLookupFailed
            ? 'Address unavailable. Coordinates: $_address'
            : _gpsNeedsReview
                ? 'Near $_address'
                : _address ?? '—';
    return AnimatedSwitcher(
      duration: AppMotion.xFast,
      switchInCurve: AppMotion.standardCurve,
      switchOutCurve: AppMotion.standardCurve,
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Container(
        key: ValueKey<String>(displayText),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              checking ? Icons.schedule_rounded : Icons.location_on_outlined,
              size: 16,
              color: checking
                  ? AppColors.textMuted
                  : AppColors.primaryDark,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: checking ? AppColors.textMuted : AppColors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUseCurrentLocationButton() {
    return Semantics(
      button: true,
      label: 'Use current location.',
      hint: 'Double-tap to center the map on your GPS position if inside Macedonia.',
      child: GestureDetector(
        onTapDown: _resolvingGps ? null : (_) => setState(() => _useLocationButtonPressed = true),
        onTapUp: (_) => setState(() => _useLocationButtonPressed = false),
        onTapCancel: () => setState(() => _useLocationButtonPressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _useLocationButtonPressed ? 0.98 : 1.0,
          duration: AppMotion.xFast,
          curve: AppMotion.standardCurve,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(12),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  AppHaptics.light();
                  _detectCurrentLocation();
                },
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: _resolvingGps
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryDark,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          size: 20,
                          color: AppColors.primaryDark,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapTilesFallback extends StatelessWidget {
  const _MapTilesFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFEFF3F6), Color(0xFFE3E8ED)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Detecting location…',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
