import 'dart:async';
import 'dart:io';

import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/theme/report_tokens.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_geo_utils.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_geocode_helpers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'location_picker_controller.g.dart';

/// Result emitted when the user confirms (or auto-confirms) a map pin.
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

class LocationPickerState {
  const LocationPickerState({
    this.address,
    this.resolvingGps = false,
    this.permissionUnavailable = false,
    this.locationLookupFailed = false,
    this.currentCenter,
    this.confirmedCenter,
    this.currentZoom = 7,
    this.gpsOutsideCoverage = false,
    this.gpsNeedsReview = false,
    this.needsConfirmation = false,
    this.geocodeRequestId = 0,
    this.lastGeocodedCenter,
    this.lastGeocodeWasMacedonia = false,
    this.geocodingInProgress = false,
    this.wasAtFenceLastMove = false,
    this.confirmButtonPressed = false,
    this.geocodeRetryCount = 0,
    this.useLocationButtonPressed = false,
    this.wasAtMaxZoomLastMove = false,
  });

  final String? address;
  final bool resolvingGps;
  final bool permissionUnavailable;
  final bool locationLookupFailed;
  final LatLng? currentCenter;
  final LatLng? confirmedCenter;
  final double currentZoom;
  final bool gpsOutsideCoverage;
  final bool gpsNeedsReview;
  final bool needsConfirmation;
  final int geocodeRequestId;
  final LatLng? lastGeocodedCenter;
  final bool lastGeocodeWasMacedonia;
  final bool geocodingInProgress;
  final bool wasAtFenceLastMove;
  final bool confirmButtonPressed;
  final int geocodeRetryCount;
  final bool useLocationButtonPressed;
  final bool wasAtMaxZoomLastMove;

  bool get currentPositionIsInMacedoniaByApi =>
      lastGeocodedCenter != null &&
      currentCenter != null &&
      locationPickerSameLatLng(currentCenter, lastGeocodedCenter) &&
      lastGeocodeWasMacedonia;

  LocationPickerState copyWith({
    String? address,
    bool? resolvingGps,
    bool? permissionUnavailable,
    bool? locationLookupFailed,
    LatLng? currentCenter,
    bool clearCurrentCenter = false,
    LatLng? confirmedCenter,
    bool clearConfirmedCenter = false,
    double? currentZoom,
    bool? gpsOutsideCoverage,
    bool? gpsNeedsReview,
    bool? needsConfirmation,
    int? geocodeRequestId,
    LatLng? lastGeocodedCenter,
    bool clearLastGeocodedCenter = false,
    bool? lastGeocodeWasMacedonia,
    bool? geocodingInProgress,
    bool? wasAtFenceLastMove,
    bool? confirmButtonPressed,
    int? geocodeRetryCount,
    bool? useLocationButtonPressed,
    bool? wasAtMaxZoomLastMove,
  }) {
    return LocationPickerState(
      address: address ?? this.address,
      resolvingGps: resolvingGps ?? this.resolvingGps,
      permissionUnavailable:
          permissionUnavailable ?? this.permissionUnavailable,
      locationLookupFailed: locationLookupFailed ?? this.locationLookupFailed,
      currentCenter: clearCurrentCenter
          ? null
          : (currentCenter ?? this.currentCenter),
      confirmedCenter: clearConfirmedCenter
          ? null
          : (confirmedCenter ?? this.confirmedCenter),
      currentZoom: currentZoom ?? this.currentZoom,
      gpsOutsideCoverage: gpsOutsideCoverage ?? this.gpsOutsideCoverage,
      gpsNeedsReview: gpsNeedsReview ?? this.gpsNeedsReview,
      needsConfirmation: needsConfirmation ?? this.needsConfirmation,
      geocodeRequestId: geocodeRequestId ?? this.geocodeRequestId,
      lastGeocodedCenter: clearLastGeocodedCenter
          ? null
          : (lastGeocodedCenter ?? this.lastGeocodedCenter),
      lastGeocodeWasMacedonia:
          lastGeocodeWasMacedonia ?? this.lastGeocodeWasMacedonia,
      geocodingInProgress: geocodingInProgress ?? this.geocodingInProgress,
      wasAtFenceLastMove: wasAtFenceLastMove ?? this.wasAtFenceLastMove,
      confirmButtonPressed: confirmButtonPressed ?? this.confirmButtonPressed,
      geocodeRetryCount: geocodeRetryCount ?? this.geocodeRetryCount,
      useLocationButtonPressed:
          useLocationButtonPressed ?? this.useLocationButtonPressed,
      wasAtMaxZoomLastMove: wasAtMaxZoomLastMove ?? this.wasAtMaxZoomLastMove,
    );
  }
}

/// Map-picker state and GPS / reverse-geocode logic (no [BuildContext]).
@riverpod
class LocationPickerController extends _$LocationPickerController {
  late final MapController mapController;
  late LocationService _locationService;
  void Function(LocationPickerResult result)? _onLocationChanged;

  Timer? _geocodeDebounce;
  Timer? _stableAutoConfirmTimer;
  bool _disposed = false;

  static final LatLngBounds macedoniaBounds = locationPickerMacedoniaBounds();

  @override
  LocationPickerState build(double? initialLatitude, double? initialLongitude) {
    mapController = MapController();
    _locationService = ref.read(locationServiceProvider);
    _disposed = false;

    ref.onDispose(() {
      _disposed = true;
      _geocodeDebounce?.cancel();
      _stableAutoConfirmTimer?.cancel();
      mapController.dispose();
    });

    return const LocationPickerState();
  }

  // ignore: use_setters_to_change_properties, imperative DI wiring (write-only)
  void setLocationService(LocationService service) {
    _locationService = service;
  }

  // ignore: use_setters_to_change_properties, registers parent callback (write-only)
  void setOnLocationChanged(
    void Function(LocationPickerResult result) callback,
  ) {
    _onLocationChanged = callback;
  }

  void safeMapMove(LatLng center, double zoom) {
    if (_disposed) return;
    try {
      mapController.move(center, zoom);
    } catch (_) {
      // Map may not be ready yet; ignore.
    }
  }

  /// Call once after the first frame (from the widget).
  void startInitialFlow({
    required double? initialLatitude,
    required double? initialLongitude,
  }) {
    if (_disposed) return;
    if (initialLatitude != null && initialLongitude != null) {
      final LatLng initial = LatLng(initialLatitude, initialLongitude);
      final int requestId = state.geocodeRequestId + 1;
      state = state.copyWith(
        currentCenter: initial,
        confirmedCenter: initial,
        currentZoom: 16,
        lastGeocodedCenter: initial,
        lastGeocodeWasMacedonia: true,
        geocodingInProgress: true,
        geocodeRequestId: requestId,
      );
      safeMapMove(initial, 16);
      unawaited(
        reverseGeocode(
          initial,
          fromUser: false,
          autoConfirm: false,
          requestId: requestId,
        ),
      );
    } else {
      unawaited(detectCurrentLocation());
    }
  }

  Future<bool> _ensurePermission() async {
    if (!await _locationService.isLocationServiceEnabled()) {
      return false;
    }
    AppLocationPermission permission = await _locationService.checkPermission();
    if (permission == AppLocationPermission.denied) {
      permission = await _locationService.requestPermission();
    }
    return permission != AppLocationPermission.denied &&
        permission != AppLocationPermission.deniedForever;
  }

  Future<void> detectCurrentLocation() async {
    if (state.resolvingGps || _disposed) return;
    state = state.copyWith(
      resolvingGps: true,
      permissionUnavailable: false,
      gpsOutsideCoverage: false,
      gpsNeedsReview: false,
      locationLookupFailed: false,
    );

    try {
      final bool ok = await _ensurePermission();
      if (_disposed) return;
      if (!ok) {
        AppHaptics.warning();
        state = state.copyWith(
          resolvingGps: false,
          permissionUnavailable: true,
          gpsOutsideCoverage: false,
        );
        return;
      }

      final GeoPosition pos = await _locationService.getCurrentPosition(
        accuracy: AppGeoAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );

      if (_disposed) return;

      if (!ReportGeoFence.contains(pos.latitude, pos.longitude)) {
        AppHaptics.warning();
        state = state.copyWith(
          resolvingGps: false,
          gpsOutsideCoverage: true,
          gpsNeedsReview: false,
          needsConfirmation: false,
        );
        return;
      }

      final LatLng position = LatLng(pos.latitude, pos.longitude);
      final double acc = pos.horizontalAccuracyMeters ?? 0;
      final bool needsReview = acc > 60;
      final int requestId = state.geocodeRequestId + 1;
      state = state.copyWith(
        currentCenter: position,
        currentZoom: 17.5,
        needsConfirmation: true,
        resolvingGps: false,
        permissionUnavailable: false,
        gpsOutsideCoverage: false,
        gpsNeedsReview: needsReview,
        geocodeRequestId: requestId,
      );
      safeMapMove(position, 17.5);
      await reverseGeocode(
        position,
        fromUser: false,
        autoConfirm: false,
        requestId: requestId,
      );
    } catch (_) {
      if (!_disposed) {
        AppHaptics.warning();
        state = state.copyWith(
          resolvingGps: false,
          locationLookupFailed: true,
          gpsNeedsReview: true,
        );
      }
    }
  }

  // ignore: avoid_positional_boolean_parameters, flutter_map PositionCallback signature
  void onMapMoved(MapCamera position, bool hasGesture) {
    if (!hasGesture) {
      state = state.copyWith(
        wasAtFenceLastMove: false,
        wasAtMaxZoomLastMove: false,
      );
      return;
    }

    final LatLng newCenter = position.center;
    final double newZoom = position.zoom;

    final bool atFence = locationPickerIsNearGeoFence(
      newCenter.latitude,
      newCenter.longitude,
    );
    if (atFence && !state.wasAtFenceLastMove) {
      AppHaptics.warning();
    }

    const double kMaxZoom = 19;
    final bool atMaxZoom = newZoom >= kMaxZoom;

    if (_disposed) return;
    final int requestId = state.geocodeRequestId + 1;
    state = state.copyWith(
      currentZoom: newZoom,
      wasAtFenceLastMove: atFence,
      wasAtMaxZoomLastMove: atMaxZoom,
      currentCenter: newCenter,
      needsConfirmation: !locationPickerSameLatLng(
        newCenter,
        state.confirmedCenter,
      ),
      gpsOutsideCoverage: false,
      gpsNeedsReview: false,
      geocodingInProgress: true,
      geocodeRequestId: requestId,
    );
    _geocodeDebounce?.cancel();
    _stableAutoConfirmTimer?.cancel();
    _geocodeDebounce = Timer(ReportTokens.locationGeocodeDebounceMap, () {
      if (state.currentCenter != null) {
        unawaited(
          reverseGeocode(
            state.currentCenter!,
            fromUser: hasGesture,
            requestId: requestId,
          ),
        );
      } else if (!_disposed) {
        state = state.copyWith(geocodingInProgress: false);
      }
    });
    _scheduleStableAutoConfirm(newCenter);
  }

  void _scheduleStableAutoConfirm(LatLng center) {
    _stableAutoConfirmTimer?.cancel();
    _stableAutoConfirmTimer = Timer(ReportTokens.locationAutoConfirmStable, () {
      if (_disposed) return;
      if (state.currentCenter == null ||
          !locationPickerSameLatLng(state.currentCenter, center)) {
        return;
      }
      if (!ReportGeoFence.contains(center.latitude, center.longitude)) {
        return;
      }
      if (!state.needsConfirmation) {
        return;
      }
      if (!state.currentPositionIsInMacedoniaByApi) {
        return;
      }
      confirmSelection(fromUser: false);
    });
  }

  Future<void> reverseGeocode(
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
      if (_disposed || requestId != state.geocodeRequestId) return;
      final LocationPlacemarkSummary summary =
          summarizePlacemarksForLocationPicker(placemarks, position);
      state = state.copyWith(
        geocodingInProgress: false,
        lastGeocodedCenter: position,
        lastGeocodeWasMacedonia: summary.isMacedonia,
        address: summary.addressLine,
        locationLookupFailed: false,
        geocodeRetryCount: 0,
        needsConfirmation:
            summary.isMacedonia &&
            !locationPickerSameLatLng(position, state.confirmedCenter),
      );
      if (autoConfirm) {
        confirmSelection(fromUser: fromUser);
      }
    } catch (e, st) {
      if (e is! SocketException &&
          e is! TimeoutException &&
          e is! FormatException) {
        await Sentry.captureException(e, stackTrace: st);
      }
      if (!_disposed && requestId == state.geocodeRequestId) {
        state = state.copyWith(
          geocodingInProgress: false,
          lastGeocodedCenter: position,
          lastGeocodeWasMacedonia: false,
          address: locationPickerCoordinateFallback(position),
          locationLookupFailed: true,
          needsConfirmation: !locationPickerSameLatLng(
            position,
            state.confirmedCenter,
          ),
        );
      }
      if (autoConfirm) {
        confirmSelection(fromUser: fromUser);
      }
    }
  }

  Future<void> retryGeocode() async {
    final LatLng? center = state.currentCenter;
    if (center == null || state.geocodingInProgress || _disposed) return;
    final int requestId = state.geocodeRequestId + 1;
    state = state.copyWith(
      geocodeRetryCount: state.geocodeRetryCount + 1,
      geocodingInProgress: true,
      geocodeRequestId: requestId,
    );
    await reverseGeocode(
      center,
      fromUser: false,
      autoConfirm: false,
      requestId: requestId,
    );
  }

  void confirmSelection({required bool fromUser}) {
    final LatLng? position = state.currentCenter;
    if (position == null || _disposed) return;
    if (!state.currentPositionIsInMacedoniaByApi) {
      AppHaptics.warning();
      return;
    }
    state = state.copyWith(
      confirmedCenter: position,
      needsConfirmation: false,
      gpsNeedsReview: false,
    );
    AppHaptics.success();
    _notifyParent(position, isInMacedonia: true, fromUser: fromUser);
  }

  void _notifyParent(
    LatLng position, {
    required bool isInMacedonia,
    required bool fromUser,
  }) {
    _onLocationChanged?.call(
      LocationPickerResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: state.address,
        isInMacedonia: isInMacedonia,
        fromUser: fromUser,
      ),
    );
  }

  void setConfirmButtonPressed({required bool pressed}) {
    if (_disposed) return;
    state = state.copyWith(confirmButtonPressed: pressed);
  }

  void setUseLocationButtonPressed({required bool pressed}) {
    if (_disposed) return;
    state = state.copyWith(useLocationButtonPressed: pressed);
  }
}
