import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/utils/civic_actor_display.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_avatar.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class SiteReportedRow extends StatelessWidget {
  const SiteReportedRow({
    super.key,
    required this.reporterName,
    this.reporterIsDeleted = false,
    required this.reportedAgo,
    this.reporterAvatarUrl,
    this.onTap,
  });

  final String reporterName;
  final bool reporterIsDeleted;
  final String reportedAgo;
  final String? reporterAvatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String displayName = civicActorDisplayLabel(
      context.l10n,
      displayName: reporterName,
      isDeleted: reporterIsDeleted,
    );
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget row = Row(
      children: <Widget>[
        AppAvatar(
          name: displayName,
          size: 28,
          fontSize: 11,
          imageUrl: reporterIsDeleted ? null : reporterAvatarUrl,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.cardSubtitle(
                textTheme,
              ).copyWith(height: 1.35),
              children: <TextSpan>[
                TextSpan(text: context.l10n.siteDetailReportedByPrefix),
                TextSpan(
                  text: displayName,
                  style: AppTypography.cardSubtitle(textTheme).copyWith(
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
