import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';

enum DirectionsSheetMode {
  directions,
  viewLocation,
}

class DirectionsSheet extends StatelessWidget {
  const DirectionsSheet({
    super.key,
    this.mode = DirectionsSheetMode.directions,
    required this.onAppleMapsTap,
    required this.onGoogleMapsTap,
    required this.onDismiss,
  });

  final DirectionsSheetMode mode;
  final VoidCallback onAppleMapsTap;
  final VoidCallback onGoogleMapsTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final bool isViewLocation = mode == DirectionsSheetMode.viewLocation;
    return ReportSheetScaffold(
      title: isViewLocation ? 'View location' : 'Open in Maps',
      subtitle: isViewLocation
          ? 'Choose which app to view this location on a map.'
          : 'Choose which app to get directions.',
      trailing: ReportCircleIconButton(
        icon: Icons.close,
        semanticLabel: 'Close',
        onTap: onDismiss,
      ),
      maxHeightFactor: 0.5,
      child: ListView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          ReportActionTile(
            icon: Icons.place_rounded,
            title: 'Apple Maps',
            subtitle: 'Built-in maps on this device.',
            tone: ReportSurfaceTone.neutral,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
            onTap: onAppleMapsTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          ReportActionTile(
            icon: Icons.map_rounded,
            title: 'Google Maps',
            subtitle: 'Web and Google Maps app.',
            tone: ReportSurfaceTone.neutral,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
            onTap: onGoogleMapsTap,
          ),
        ],
      ),
    );
  }
}
