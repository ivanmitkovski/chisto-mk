import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? _currentAddress;
  bool _resolvingLocation = false;
  final LatLng _mapCenter = const LatLng(41.6086, 21.7453); // Approx center of Macedonia
  LatLng? _selectedPosition;
  final MapController _mapController = MapController();

  @override
  void dispose() {
    super.dispose();
  }

  bool _isInMacedonia(double lat, double lng) {
    // Rough bounding box for Macedonia.
    return lat >= 40.8 && lat <= 42.4 && lng >= 20.4 && lng <= 23.1;
  }

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        AppSnack.show(
          context,
          message: 'Location services are disabled. Please enable them in Settings.',
          type: AppSnackType.warning,
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        AppSnack.show(
          context,
          message:
              'Location permission denied. You can enable it in Settings to use this feature.',
          type: AppSnackType.warning,
        );
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        AppSnack.show(
          context,
          message: 'Location permission is permanently denied. Opening Settings…',
          type: AppSnackType.warning,
          duration: const Duration(seconds: 3),
        );
      }
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  Future<void> _useCurrentLocation() async {
    if (_resolvingLocation) {
      return;
    }
    AppHaptics.light();
    setState(() => _resolvingLocation = true);

    try {
      final bool ok = await _ensurePermission();
      if (!ok) {
        setState(() => _resolvingLocation = false);
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!_isInMacedonia(pos.latitude, pos.longitude)) {
        if (mounted) {
          AppSnack.show(
            context,
            message: 'Currently we only support locations in Macedonia.',
            type: AppSnackType.info,
          );
        }
        setState(() => _resolvingLocation = false);
        return;
      }
      // Fallback label in case reverse geocoding fails.
      String label =
          'Lat ${pos.latitude.toStringAsFixed(4)}, Lng ${pos.longitude.toStringAsFixed(4)}';
      try {
        final List<Placemark> placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final Placemark p = placemarks.first;
          final String street = p.street ?? '';
          final String locality = p.locality ?? '';
          final String country = p.country ?? '';
          final List<String> parts = <String>[street, locality, country]
              .where((String s) => s.trim().isNotEmpty)
              .toList();
          if (parts.isNotEmpty) {
            label = parts.join(', ');
          }
        }
      } catch (_) {
        // Keep the coordinates-based fallback label.
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _currentAddress = label;
        _selectedPosition = LatLng(pos.latitude, pos.longitude);
        _resolvingLocation = false;
      });
      // Zoom in closer when auto-detecting location so the user can better
      // verify the exact spot.
      _mapController.move(_selectedPosition!, 17);
      AppHaptics.success();
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _resolvingLocation = false);
      AppSnack.show(
        context,
        message: 'Could not resolve your location. Please try again.',
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.panelBackground,
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SafeArea(
            child: AnimatedPadding(
              duration: AppMotion.medium,
              curve: AppMotion.emphasized,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.radiusSm),
                    const Text(
                      'Choose your location',
                      style: AppTypography.authHeadline,
                    ),
                    const SizedBox(height: AppSpacing.radius10),
                    const Text(
                      'We use your location to show cleanups and reports near you.',
                      style: AppTypography.authSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radius22),
                      child: SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedPosition ?? _mapCenter,
                                initialZoom: _selectedPosition != null ? 14 : 7,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  // Lightweight OSM tiles for auth/onboarding flow.
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  maxNativeZoom: 19,
                                  userAgentPackageName: 'chisto_mobile',
                                ),
                                if (_selectedPosition != null)
                                  MarkerLayer(
                                    markers: <Marker>[
                                      Marker(
                                        point: _selectedPosition!,
                                        width: 30,
                                        height: 30,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            // Keep the green pin but soften it so
                                            // underlying imagery stays readable.
                                            color: AppColors.primaryDark
                                                .withValues(alpha: 0.82),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            if (_resolvingLocation && _selectedPosition == null)
                              const Positioned.fill(
                                child: IgnorePointer(
                                  child: _MapTilesFallback(),
                                ),
                              ),
                            Positioned(
                              left: AppSpacing.md,
                              right: AppSpacing.md,
                              top: AppSpacing.md,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.radiusSm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                ),
                                child: Text(
                                  _currentAddress ??
                                      'Use current location to update this area',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.pillLabel,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.radiusPill),
                    PrimaryButton(
                      label: _resolvingLocation ? 'Detecting location…' : 'Use current location',
                      enabled: !_resolvingLocation,
                      onPressed: _resolvingLocation ? null : _useCurrentLocation,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "We only use your location to show nearby cleanups. We don't track you in the background.",
                      style: AppTypography.cardSubtitle.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
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
          colors: <Color>[
            AppColors.inputFill,
            AppColors.inputBorder,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double tileSize = AppSpacing.xl;
    final Paint linePaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 0.7;

    for (double x = 0; x <= size.width; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
