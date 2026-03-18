import 'package:flutter/cupertino.dart';
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
import 'package:chisto_mobile/shared/utils/cached_tile_provider.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Shown only after OTP verification in the sign-up flow.
/// User picks location, then taps "Confirm and continue" to go to the feed.
/// Sign-in and returning users skip this and go straight to home.
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
  bool _showTileLoadingOverlay = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showTileLoadingOverlay = false);
    });
  }

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
      // Move map after layout so tiles load correctly; zoom 15 = neighborhood view (avoids over-zoom).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedPosition != null) {
          _mapController.move(_selectedPosition!, 15);
        }
      });
      AppHaptics.success();
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

  void _confirmAndGoToFeed() {
    if (_selectedPosition == null) return;
    AppHaptics.light();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (Route<dynamic> route) => false,
    );
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
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            FlutterMap(
                              key: ValueKey<bool>(_selectedPosition != null),
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedPosition ?? _mapCenter,
                                initialZoom: _selectedPosition != null ? 15 : 7,
                                minZoom: 1.5,
                                maxZoom: 18,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                                  subdomains: const <String>['a', 'b', 'c', 'd'],
                                  maxNativeZoom: 20,
                                  userAgentPackageName: 'chisto_mobile',
                                  retinaMode: false,
                                  tileProvider: createCachedTileProvider(maxStaleDays: 30),
                                  tileDisplay: TileDisplay.instantaneous(),
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
                            if (_showTileLoadingOverlay ||
                                (_resolvingLocation && _selectedPosition == null))
                              const Positioned.fill(
                                child: IgnorePointer(child: _MapTileSkeleton()),
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
                                  color: AppColors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                    Semantics(
                      button: true,
                      label: _resolvingLocation
                          ? 'Detecting location…'
                          : _selectedPosition != null
                              ? 'Continue'
                              : 'Use current location',
                      child: PrimaryButton(
                        label: _resolvingLocation
                            ? 'Detecting location…'
                            : _selectedPosition != null
                                ? 'Continue'
                                : 'Use current location',
                        enabled: !_resolvingLocation,
                        onPressed: _resolvingLocation
                            ? null
                            : _selectedPosition != null
                                ? _confirmAndGoToFeed
                                : _useCurrentLocation,
                      ),
                    ),
                    AnimatedSize(
                      duration: AppMotion.standard,
                      curve: AppMotion.emphasized,
                      alignment: Alignment.topCenter,
                      child: _selectedPosition != null && !_resolvingLocation
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const SizedBox(height: AppSpacing.sm),
                                Center(
                                  child: Semantics(
                                    button: true,
                                    label: 'Use a different location',
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      minimumSize: Size.zero,
                                      onPressed: _useCurrentLocation,
                                      child: Text(
                                        'Use a different location',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
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

/// Apple-style tile skeleton: grid of rounded tiles with a subtle left-to-right shimmer.
class _MapTileSkeleton extends StatefulWidget {
  const _MapTileSkeleton();

  @override
  State<_MapTileSkeleton> createState() => _MapTileSkeletonState();
}

class _MapTileSkeletonState extends State<_MapTileSkeleton>
    with SingleTickerProviderStateMixin {
  static const int _columns = 4;
  static const double _gap = 6;
  static const double _radius = 8;

  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (BuildContext context, Widget? child) {
        final double t = _shimmerController.value;
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const <Color>[
                AppColors.inputFill,
                AppColors.panelBackground,
                AppColors.inputFill,
              ],
              stops: <double>[
                (t - 0.25).clamp(0.0, 1.0),
                t,
                (t + 0.25).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child!,
        );
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.panelBackground,
        padding: const EdgeInsets.all(_gap / 2),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final double totalGapW = _gap * (_columns - 1);
            final double tileW = (w - totalGapW - _gap) / _columns;
            final int rows = ((h + _gap) / (tileW + _gap)).floor().clamp(2, 6);
            final double totalGapH = _gap * (rows - 1);
            final double tileH = (h - totalGapH - _gap) / rows;
            return Column(
              children: List<Widget>.generate(rows, (int row) {
                return Padding(
                  padding: EdgeInsets.only(bottom: row < rows - 1 ? _gap : 0),
                  child: Row(
                    children: List<Widget>.generate(_columns, (int col) {
                      return Padding(
                        padding: EdgeInsets.only(right: col < _columns - 1 ? _gap : 0),
                        child: Container(
                          width: tileW,
                          height: tileH,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(_radius),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
