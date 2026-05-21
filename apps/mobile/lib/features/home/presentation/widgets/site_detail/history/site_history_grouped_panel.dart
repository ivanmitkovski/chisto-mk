import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_radii.dart';
import 'package:chisto_mobile/core/theme/app_shadows.dart';
import 'package:flutter/material.dart';

/// Rounded grouped panel used for History status and section entry lists.
class SiteHistoryGroupedPanel extends StatelessWidget {
  const SiteHistoryGroupedPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppRadii.r18,
        boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.9),
        ),
      ),
      child: child,
    );
  }
}
