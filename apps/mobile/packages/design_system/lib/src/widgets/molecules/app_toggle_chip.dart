import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Shared selectable chip used by filter sheets and compact control bars.
class AppToggleChip extends StatelessWidget {
  const AppToggleChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.accentColor,
    this.icon,
    this.showDot,
    this.semanticLabel,
    this.semanticHint,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  /// Optional accent for active state + dot indicator.
  final Color? accentColor;

  /// Optional leading icon instead of the dot indicator.
  final IconData? icon;

  /// Override dot visibility. Defaults to true when [accentColor] is provided
  /// and no [icon] is set.
  final bool? showDot;

  final String? semanticLabel;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool dotVisible = showDot ?? (accentColor != null && icon == null);
    final Color resolvedAccent = accentColor ?? AppColors.primaryDark;
    final bool disableAnimations = MediaQuery.disableAnimationsOf(context);

    final Color background = isActive
        ? (accentColor != null
              ? resolvedAccent.withValues(alpha: 0.12)
              : AppColors.feedPillSelectedFill)
        : AppColors.panelBackground;
    final Color border = isActive
        ? (accentColor != null
              ? resolvedAccent.withValues(alpha: 0.5)
              : AppColors.feedPillSelectedBorder)
        : AppColors.divider.withValues(alpha: 0.6);
    final Color foreground = isActive
        ? (dotVisible ? AppColors.textPrimary : resolvedAccent)
        : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: isActive,
      label: semanticLabel ?? label,
      hint: semanticHint,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: AnimatedContainer(
              duration: disableAnimations ? Duration.zero : AppMotion.fast,
              curve: AppMotion.emphasized,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: border, width: isActive ? 1.4 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 14, color: foreground),
                    const SizedBox(width: AppSpacing.xxs),
                  ] else if (dotVisible) ...<Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: resolvedAccent.withValues(
                          alpha: isActive ? 1 : 0.55,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: AppTypography.chipLabel(textTheme).copyWith(
                      color: foreground,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
