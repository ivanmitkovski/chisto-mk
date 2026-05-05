import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';

/// Back + title + optional subtitle for profile sub-screens (not [ProfileScreen] gradient header).
///
/// Matches [ProfileGeneralInfoScreen] / [ProfileLanguageScreen] chrome: [AppBackButton] on
/// [AppColors.inputFill], then title and subtitle with consistent typography.
class ProfileSubScreenHeader extends StatelessWidget {
  const ProfileSubScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.belowSubtitle,
    this.onBack,
    this.includeBottomSpacing = true,
  });

  final String title;
  final String? subtitle;
  final Widget? belowSubtitle;
  final VoidCallback? onBack;

  /// When false, callers add their own gap before the next block (e.g. skeletons).
  final bool includeBottomSpacing;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            0,
          ),
          child: AppBackButton(
            backgroundColor: AppColors.inputFill,
            onPressed: onBack,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (belowSubtitle != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                belowSubtitle!,
              ],
            ],
          ),
        ),
        if (includeBottomSpacing) const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
