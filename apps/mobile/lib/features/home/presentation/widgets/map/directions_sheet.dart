import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';

/// Bottom sheet for choosing Apple Maps or Google Maps to get directions.
class DirectionsSheet extends StatelessWidget {
  const DirectionsSheet({
    super.key,
    required this.onAppleMapsTap,
    required this.onGoogleMapsTap,
    required this.onDismiss,
  });

  final VoidCallback onAppleMapsTap;
  final VoidCallback onGoogleMapsTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ReportSheetScaffold(
      title: 'Open in Maps',
      subtitle: 'Choose which app to get directions.',
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
