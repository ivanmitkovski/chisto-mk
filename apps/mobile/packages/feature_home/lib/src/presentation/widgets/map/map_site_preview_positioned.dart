import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/widgets/map/map_layout_tokens.dart';
import 'package:feature_home/src/presentation/widgets/map/site_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapSitePreviewPositioned extends StatelessWidget {
  const MapSitePreviewPositioned({
    super.key,
    required this.site,
    required this.userLocation,
    required this.coords,
    this.useDarkTiles = false,
    required this.onGetDirections,
    required this.onViewDetails,
    required this.onDismiss,
  });

  final PollutionSite site;
  final LatLng? userLocation;
  final Map<String, LatLng> coords;
  final bool useDarkTiles;
  final void Function(PollutionSite site) onGetDirections;
  final VoidCallback onViewDetails;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: AppSpacing.lg + 72,
      height: MapLayoutTokens.previewHeight(MediaQuery.sizeOf(context).width),
      child: SitePreviewSheet(
        key: ValueKey<String>(site.id),
        site: site,
        userLocation: userLocation,
        siteCoordinates: coords,
        useDarkTiles: useDarkTiles,
        onGetDirections: onGetDirections,
        onViewDetails: onViewDetails,
        onDismiss: onDismiss,
      ),
    );
  }
}
