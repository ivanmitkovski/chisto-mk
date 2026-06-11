import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Visual variant for the empty-state icon well.
enum AppEmptyStateIconVariant {
  /// Neutral grey fill with muted icon (default list/tab empties).
  standard,

  /// Danger-tinted fill for error surfaces ([AppErrorView]).
  error,
}

/// Rounded-square icon well used by [AppEmptyState] and related layouts.
class AppEmptyStateIcon extends StatelessWidget {
  const AppEmptyStateIcon({
    super.key,
    required this.icon,
    this.variant = AppEmptyStateIconVariant.standard,
    this.iconKey,
    this.animateIconChanges = false,
  });

  final IconData icon;
  final AppEmptyStateIconVariant variant;
  final Object? iconKey;
  final bool animateIconChanges;

  @override
  Widget build(BuildContext context) {
    final Widget well = _IconWell(variant: variant, icon: icon);

    if (!animateIconChanges || iconKey == null) {
      return well;
    }

    return AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: AppMotion.emphasized,
      child: KeyedSubtree(key: ValueKey<Object>(iconKey!), child: well),
    );
  }
}

class _IconWell extends StatelessWidget {
  const _IconWell({required this.variant, required this.icon});

  final AppEmptyStateIconVariant variant;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color iconColor;
    switch (variant) {
      case AppEmptyStateIconVariant.standard:
        backgroundColor = AppColors.inputFill;
        iconColor = AppColors.textMuted;
      case AppEmptyStateIconVariant.error:
        backgroundColor = AppColors.accentDanger.withValues(alpha: 0.12);
        iconColor = AppColors.accentDanger;
    }

    return Container(
      width: AppSpacing.emptyStateIconBox,
      height: AppSpacing.emptyStateIconBox,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.emptyStateIconRadius),
      ),
      child: Icon(icon, size: AppSpacing.emptyStateIconSize, color: iconColor),
    );
  }
}
