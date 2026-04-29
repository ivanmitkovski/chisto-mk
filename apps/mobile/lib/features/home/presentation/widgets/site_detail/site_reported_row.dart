import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';

class SiteReportedRow extends StatelessWidget {
  const SiteReportedRow({
    super.key,
    required this.reporterName,
    required this.reportedAgo,
    this.reporterAvatarUrl,
    this.onTap,
  });

  final String reporterName;
  final String reportedAgo;
  final String? reporterAvatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget row = Row(
      children: <Widget>[
        AppAvatar(
          name: reporterName,
          size: 28,
          fontSize: 11,
          imageUrl: reporterAvatarUrl,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.cardSubtitle.copyWith(height: 1.35),
              children: <TextSpan>[
                TextSpan(text: context.l10n.siteDetailReportedByPrefix),
                TextSpan(
                  text: reporterName,
                  style: AppTypography.cardSubtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(text: '  •  $reportedAgo'),
              ],
            ),
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textMuted.withValues(alpha: 0.6),
          ),
      ],
    );

    if (onTap != null) {
      return Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.tap();
            onTap!();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.xxs,
            ),
            child: row,
          ),
        ),
      );
    }
    return row;
  }
}
