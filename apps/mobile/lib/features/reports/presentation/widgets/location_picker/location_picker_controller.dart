import 'dart:async';
import 'dart:io';

import 'package:chisto_mobile/core/location/location_service.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/theme/report_tokens.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker/location_picker_geocode_helpers.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker/location_picker_geo_utils.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

/// Mutable map-picker state and GPS / reverse-geocode logic (no [BuildContext]).
class LocationPickerController extends ChangeNotifier {
  LocationPickerController({
    required LocationService locationService,
    required void Function(LocationPickerResult result) onLocationChanged,
    this.initialLatitude,
    this.initialLongitude,
  }) : _locationService = locationService,
       _onLocationChanged = onLocationChanged;

  final LocationService _locationService;
  final void Function(LocationPickerResult) _onLocationChanged;
  final double? initialLatitude;
  final double? initialLongitude;

  final MapController mapController = MapController();

  static final LatLngBounds macedoniaBounds = locationPickerMacedoniaBounds();

  String? address;
  bool resolvingGps = false;
  bool permissionUnavailable = false;
  bool locationLookupFailed = false;
  Timer? geocodeDebounce;
  Timer? stableAutoConfirmTimer;
  LatLng? currentCenter;
  LatLng? confirmedCenter;
  double currentZoom = 7;
  bool gpsOutsideCoverage = false;
  bool gpsNeedsReview = false;
  bool needsConfirmation = false;
  int geocodeRequestId = 0;
  LatLng? lastGeocodedCenter;
  bool lastGeocodeWasMacedonia = false;
  bool geocodingInProgress = false;
  bool wasAtFenceLastMove = false;
  bool confirmButtonPressed = false;
  int geocodeRetryCount = 0;
  bool useLocationButtonPressed = false;
  bool wasAtMaxZoomLastMove = false;

  bool _disposed = false;

  bool get currentPositionIsInMacedoniaByApi =>
      lastGeocodedCenter != null &&
      currentCenter != null &&
      locationPickerSameLatLng(currentCenter, lastGeocodedCenter) &&
      lastGeocodeWasMacedonia;

  void safeMapMove(LatLng center, double zoom) {
    if (_disposed) return;
    try {
      mapController.move(center, zoom);
    } catch (_) {
      // Map may not be ready yet; ignore.
    }
  }

  /// Call once after the first frame (from the widget).
  void startInitialFlow() {
    if (_disposed) return;
    if (initialLatitude != null && initialLongitude != null) {
      final LatLng initial = LatLng(initialLatitude!, initialLongitude!);
      currentCenter = initial;
      confirmedCenter = initial;
      currentZoom = 16;
      lastGeocodedCenter = initial;
      lastGeocodeWasMacedonia = true;
      notifyListeners();
      safeMapMove(initial, 16);
      geocodingInProgress = true;
      notifyListeners();
      unawaited(
        reverseGeocode(
          initial,
          fromUser: false,
          autoConfirm: false,
          requestId: ++geocodeRequestId,
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
    if (resolvingGps || _disposed) return;
    resolvingGps = true;
    permissionUnavailable = false;
    gpsOutsideCoverage = false;
    gpsNeedsReview = false;
    locationLookupFailed = false;
    notifyListeners();

    try {
      final bool ok = await _ensurePermission();
      if (_disposed) return;
      if (!ok) {
        AppHaptics.gpsFailed();
        resolvingGps = false;
        permissionUnavailable = true;
        gpsOutsideCoverage = false;
        notifyListeners();
        return;
      }

      final GeoPosition pos = await _locationService.getCurrentPosition(
        accuracy: AppGeoAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );

      if (_disposed) return;

      if (!ReportGeoFence.contains(pos.latitude, pos.longitude)) {
        AppHaptics.gpsFailed();
        resolvingGps = false;
        gpsOutsideCoverage = true;
        gpsNeedsReview = false;
        needsConfirmation = false;
        notifyListeners();
        return;
      }

      final LatLng position = LatLng(pos.latitude, pos.longitude);
      final double acc = pos.horizontalAccuracyMeters ?? 0;
      final bool needsReview = acc > 60;
      currentCenter = position;
      currentZoom = 17.5;
      needsConfirmation = true;
      resolvingGps = false;
      permissionUnavailable = false;
      gpsOutsideCoverage = false;
      gpsNeedsReview = needsReview;
      notifyListeners();
      safeMapMove(position, 17.5);
      AppHaptics.gpsFound();
      await reverseGeocode(
        position,
        fromUser: false,
        autoConfirm: false,
        requestId: ++geocodeRequestId,
      );
    } catch (_) {
      if (!_disposed) {
        AppHaptics.gpsFailed();
        resolvingGps = false;
        locationLookupFailed = true;
        gpsNeedsReview = true;
        notifyListeners();
      }
    }
  }

  void onMapMoved(dynamic position, bool hasGesture) {
    if (!hasGesture) {
      wasAtFenceLastMove = false;
      wasAtMaxZoomLastMove = false;
      return;
    }

    final LatLng? newCenter = position.center as LatLng?;
    final double? newZoom = position.zoom as double?;
    if (newCenter == null || newZoom == null) {
      return;
    }
    currentZoom = newZoom;

    final bool atFence = locationPickerIsNearGeoFence(
      newCenter.latitude,
      newCenter.longitude,
    );
    if (atFence && !wasAtFenceLastMove) {
      AppHaptics.boundaryLimitPulse();
    }
    wasAtFenceLastMove = atFence;

    const double kMaxZoom = 19;
    final bool atMaxZoom = newZoom >= kMaxZoom;
    if (atMaxZoom && !wasAtMaxZoomLastMove) {
      AppHaptics.light();
    }
    wasAtMaxZoomLastMove = atMaxZoom;

    if (_disposed) return;
    currentCenter = newCenter;
    needsConfirmation = !locationPickerSameLatLng(newCenter, confirmedCenter);
    gpsOutsideCoverage = false;
    gpsNeedsReview = false;
    notifyListeners();
    geocodeDebounce?.cancel();
    stableAutoConfirmTimer?.cancel();
    final int requestId = ++geocodeRequestId;
    geocodingInProgress = true;
    notifyListeners();
    geocodeDebounce = Timer(ReportTokens.locationGeocodeDebounceMap, () {
      if (currentCenter != null) {
        unawaited(
          reverseGeocode(
            currentCenter!,
            fromUser: hasGesture,
            requestId: requestId,
          ),
        );
      } else if (!_disposed) {
        geocodingInProgress = false;
        notifyListeners();
      }
    });
    _scheduleStableAutoConfirm(newCenter);
  }

  void _scheduleStableAutoConfirm(LatLng center) {
    stableAutoConfirmTimer?.cancel();
    stableAutoConfirmTimer = Timer(ReportTokens.locationAutoConfirmStable, () {
      if (_disposed) return;
      if (currentCenter == null ||
          !locationPickerSameLatLng(currentCenter, center)) {
        return;
      }
      if (!ReportGeoFence.contains(center.latitude, center.longitude)) {
        return;
      }
      if (!needsConfirmation) {
        return;
      }
      if (!currentPositionIsInMacedoniaByApi) {
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
      if (_disposed || requestId != geocodeRequestId) return;
      final LocationPlacemarkSummary summary =
          summarizePlacemarksForLocationPicker(placemarks, position);
      geocodingInProgress = false;
      lastGeocodedCenter = position;
      lastGeocodeWasMacedonia = summary.isMacedonia;
      address = summary.addressLine;
      locationLookupFailed = false;
      geocodeRetryCount = 0;
      needsConfirmation = summary.isMacedonia &&
          !locationPickerSameLatLng(position, confirmedCenter);
      notifyListeners();
      if (autoConfirm) {
        confirmSelection(fromUser: fromUser);
      }
    } catch (e, st) {
      if (e is! SocketException &&
          e is! TimeoutException &&
          e is! FormatException) {
        await Sentry.captureException(e, stackTrace: st);
      }
      if (!_disposed && requestId == geocodeRequestId) {
        geocodingInProgress = false;
        lastGeocodedCenter = position;
        lastGeocodeWasMacedonia = false;
        address = locationPickerCoordinateFallback(position);
        locationLookupFailed = true;
        needsConfirmation = !locationPickerSameLatLng(position, confirmedCenter);
        notifyListeners();
      }
      if (autoConfirm) {
        confirmSelection(fromUser: fromUser);
      }
    }
  }

  Future<void> retryGeocode() async {
    final LatLng? center = currentCenter;
    if (center == null || geocodingInProgress || _disposed) return;
    AppHaptics.light();
    geocodeRetryCount += 1;
    final int requestId = ++geocodeRequestId;
    geocodingInProgress = true;
    notifyListeners();
    await reverseGeocode(
      center,
      fromUser: false,
      autoConfirm: false,
      requestId: requestId,
    );
  }

  void confirmSelection({required bool fromUser}) {
    final LatLng? position = currentCenter;
    if (position == null || _disposed) return;
    if (!currentPositionIsInMacedoniaByApi) {
      AppHaptics.locationRejected();
      return;
    }
    confirmedCenter = position;
    needsConfirmation = false;
    gpsNeedsReview = false;
    notifyListeners();
    AppHaptics.locationConfirmed();
    _notifyParent(position, isInMacedonia: true, fromUser: fromUser);
  }

  void _notifyParent(
    LatLng position, {
    required bool isInMacedonia,
    required bool fromUser,
  }) {
    _onLocationChanged(
      LocationPickerResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        isInMacedonia: isInMacedonia,
        fromUser: fromUser,
      ),
    );
  }

  void setConfirmButtonPressed(bool v) {
    if (_disposed) return;
    confirmButtonPressed = v;
    notifyListeners();
  }

  void setUseLocationButtonPressed(bool v) {
    if (_disposed) return;
    useLocationButtonPressed = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    geocodeDebounce?.cancel();
    stableAutoConfirmTimer?.cancel();
    super.dispose();
  }
}
