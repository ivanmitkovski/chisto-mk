import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class SiteReportedRow extends StatelessWidget {
  const SiteReportedRow({
    super.key,
    required this.reporterName,
    required this.reportedAgo,
    this.onTap,
  });

  final String reporterName;
  final String reportedAgo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget row = Row(
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
              children: <TextSpan>[
                const TextSpan(text: 'Reported by '),
                TextSpan(
                  text: reporterName,
                  style: const TextStyle(
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
