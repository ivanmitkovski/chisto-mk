import 'dart:ui';

import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography_surfaces.dart';
import 'package:design_system/src/widgets/atoms/app_empty_state_icon.dart';
import 'package:flutter/material.dart';

/// Frosted panel wrapper for map-style empty overlays.
///
/// Uses [AppEmptyStateIcon] and empty-state typography; pass [action] for CTAs.
class AppEmptyStatePanel extends StatelessWidget {
  const AppEmptyStatePanel({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.useDarkTiles = false,
    this.semanticsLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool useDarkTiles;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color panelFill = useDarkTiles
        ? AppColors.glassDark.withValues(alpha: 0.58)
        : AppColors.white.withValues(alpha: 0.9);
    final Color panelBorder = useDarkTiles
        ? AppColors.white.withValues(alpha: 0.14)
        : AppColors.white.withValues(alpha: 0.7);
    final Color titleColor =
        useDarkTiles ? AppColors.textOnDark : AppColors.textPrimary;
    final Color bodyColor =
        useDarkTiles ? AppColors.textOnDarkMuted : AppColors.textMuted;

    final String effectiveSemantics = semanticsLabel ??
        (subtitle != null ? '$title. $subtitle' : title);

    return Semantics(
      liveRegion: true,
      label: effectiveSemantics,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: panelFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: panelBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppEmptyStateIcon(icon: icon),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    style: AppTypographySurfaces.homeMapOverlayTitle(
                      textTheme,
                      color: titleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle!,
                      style: AppTypographySurfaces.homeMapOverlayBody(
                        textTheme,
                        color: bodyColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (action != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
