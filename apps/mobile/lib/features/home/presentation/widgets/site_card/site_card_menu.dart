import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Top-right overflow control on the feed site image strip.
class SiteCardOverflowMenuButton extends StatelessWidget {
  const SiteCardOverflowMenuButton({
    super.key,
    required this.onMenuTap,
  });

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Semantics(
        button: true,
        label: context.l10n.siteCardFeedOptionsSemantic,
        child: InkWell(
          onTap: onMenuTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(
                AppSpacing.radiusPill,
              ),
            ),
            child: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textOnDark,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
