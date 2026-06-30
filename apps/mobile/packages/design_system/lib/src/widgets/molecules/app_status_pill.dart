import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:design_system/src/widgets/organisms/app_surface/app_surface_primitives.dart';
import 'package:flutter/material.dart';

/// Read-only status badge shared across surfaces.
///
/// Delegates to [AppStatePill] for tone-based palettes and supports an optional
/// custom [color] override for one-off statuses.
class AppStatusPill extends StatelessWidget {
  const AppStatusPill({
    super.key,
    required this.label,
    this.tone = AppSurfaceTone.neutral,
    this.icon,
    this.emphasized = false,
    this.dense = false,
    this.color,
  });

  final String label;
  final AppSurfaceTone tone;
  final IconData? icon;
  final bool emphasized;
  final bool dense;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    if (color == null) {
      return AppStatePill(
        label: label,
        tone: tone,
        icon: icon,
        emphasized: emphasized,
        dense: dense,
      );
    }

    final Brightness brightness = ThemeData.estimateBrightnessForColor(color!);
    final Color foreground = brightness == Brightness.dark
        ? AppColors.white
        : AppColors.textPrimary;
    final double backgroundAlpha = emphasized ? 0.26 : 0.14;
    final double borderAlpha = emphasized ? 0.56 : 0.38;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: dense ? 3 : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color!.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
        border: Border.all(color: color!.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 13, color: foreground),
            SizedBox(width: dense ? AppSpacing.xxs : AppSpacing.xs),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.badgeLabel(
              textTheme,
            ).copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
