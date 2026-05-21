import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_radii.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

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
      AppInlineBannerTone.info =>
        AppColors.primary.withValues(alpha: 0.08),
      AppInlineBannerTone.warning =>
        AppColors.accentDanger.withValues(alpha: 0.08),
      AppInlineBannerTone.error =>
        AppColors.accentDanger.withValues(alpha: 0.12),
    };

    final Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.md,
      ),
      child: Text(
        message,
        style: AppTypography.textTheme.bodySmall!.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    if (onTap == null) {
      return content;
    }
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: content,
      ),
    );
  }
}
