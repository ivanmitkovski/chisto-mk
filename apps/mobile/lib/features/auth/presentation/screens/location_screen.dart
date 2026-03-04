import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
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
    // Rough bounding box for North Macedonia.
    return lat >= 40.8 && lat <= 42.4 && lng >= 20.4 && lng <= 23.1;
  }

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them in Settings.')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. You can enable it in Settings to use this feature.'),
          ),
        );
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is permanently denied. Opening Settings…'),
            duration: Duration(seconds: 3),
          ),
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
    HapticFeedback.lightImpact();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Currently we only support locations in North Macedonia.'),
            ),
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
      _mapController.move(_selectedPosition!, 14);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _resolvingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resolve your location. Please try again.')),
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
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Choose your location',
                      style: AppTypography.authHeadline,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'We use your location to show cleanups and reports near you.',
                      style: AppTypography.authSubtitle,
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
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
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                            color: AppColors.primaryDark,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
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
                              left: 16,
                              right: 16,
                              top: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: _resolvingLocation ? 'Detecting location…' : 'Use current location',
                      enabled: !_resolvingLocation,
                      onPressed: _resolvingLocation ? null : _useCurrentLocation,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'We only use your location to show nearby cleanups. We don’t track you in the background.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
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
            Color(0xFFEFF3F6),
            Color(0xFFE3E8ED),
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
    const double tileSize = 32;
    final Paint linePaint = Paint()
      ..color = const Color(0xFFE0E5EB)
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
