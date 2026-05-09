import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
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
      title: isViewLocation
          ? context.l10n.mapDirectionsSheetViewLocation
          : context.l10n.mapDirectionsSheetOpenInMaps,
      subtitle: isViewLocation
          ? context.l10n.mapDirectionsSheetSubtitleViewLocation
          : context.l10n.mapDirectionsSheetSubtitleDirections,
      trailing: ReportCircleIconButton(
        icon: Icons.close,
        semanticLabel: context.l10n.commonClose,
        onTap: onDismiss,
      ),
      maxHeightFactor: 0.5,
      child: ListView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          ReportActionTile(
            icon: Icons.place_rounded,
            title: context.l10n.mapDirectionsAppleMapsTitle,
            subtitle: context.l10n.mapDirectionsAppleMapsSubtitle,
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
            title: context.l10n.mapDirectionsGoogleMapsTitle,
            subtitle: context.l10n.mapDirectionsGoogleMapsSubtitle,
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
