import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_radii.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/material.dart';

enum AppInlineBannerTone { info, warning, error }

/// Subtle full-width status strip (stale cache, rate limit, offline).
class AppInlineBanner extends StatelessWidget {
  const AppInlineBanner({
    super.key,
    required this.message,
    this.tone = AppInlineBannerTone.warning,
    this.onTap,
  });

  final String message;
  final AppInlineBannerTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = switch (tone) {
      AppInlineBannerTone.info => AppColors.primary.withValues(alpha: 0.08),
      AppInlineBannerTone.warning => AppColors.error.withValues(alpha: 0.08),
      AppInlineBannerTone.error => AppColors.error.withValues(alpha: 0.12),
    };

    final Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: background, borderRadius: AppRadii.md),
      child: Text(
        message,
        style: AppTypography.textTheme.bodySmall!.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    final Widget banner = Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: content,
    );

    if (onTap == null) {
      return banner;
    }
    return Material(
      color: AppColors.transparent,
      child: InkWell(onTap: onTap, borderRadius: AppRadii.md, child: banner),
    );
  }
}
