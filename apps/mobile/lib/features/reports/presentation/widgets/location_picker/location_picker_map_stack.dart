import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker/location_picker_map_tiles_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Satellite map, center pin, GPS control, and resolving overlay for [LocationPicker].
class LocationPickerMapStack extends StatelessWidget {
  const LocationPickerMapStack({
    super.key,
    required this.mapController,
    required this.center,
    required this.zoom,
    required this.macedoniaBounds,
    required this.onPositionChanged,
    required this.hasConfirmedLocation,
    required this.showGpsResolvingOverlay,
    required this.useCurrentLocationButton,
  });

  final MapController mapController;
  final LatLng center;
  final double zoom;
  final LatLngBounds macedoniaBounds;
  final PositionCallback onPositionChanged;
  final bool hasConfirmedLocation;
  final bool showGpsResolvingOverlay;
  final Widget useCurrentLocationButton;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                maxZoom: 19,
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: macedoniaBounds,
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onPositionChanged: onPositionChanged,
              ),
              children: <Widget>[
                TileLayer(
                  urlTemplate:
                      'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  maxNativeZoom: 19,
                  userAgentPackageName: 'chisto_mobile',
                ),
              ],
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: AnimatedScale(
                  scale: hasConfirmedLocation ? 1.08 : 1.0,
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasized,
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 40,
                    color: AppColors.primaryDark.withValues(alpha: 0.84),
                    shadows: <Shadow>[
                      Shadow(
                        color: AppColors.black.withValues(alpha: 0.2),
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
              child: useCurrentLocationButton,
            ),
            if (showGpsResolvingOverlay)
              const Positioned.fill(
                child: LocationPickerMapTilesFallback(),
              ),
          ],
        ),
      ),
    );
  }
}
