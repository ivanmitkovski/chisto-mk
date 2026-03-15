import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class SiteStatsRow extends StatelessWidget {
  const SiteStatsRow({
    super.key,
    required this.site,
    this.onScoreTap,
    this.onCommentsTap,
    this.onParticipantsTap,
    this.onDistanceTap,
  });

  final PollutionSite site;
  final VoidCallback? onScoreTap;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onParticipantsTap;
  final VoidCallback? onDistanceTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _StatChip(
          iconWidget: SvgPicture.asset(
            AppAssets.cardArrowUp,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppColors.primaryDark,
              BlendMode.srcIn,
            ),
          ),
          label: '+${site.score}',
          color: AppColors.primaryDark,
          onTap: onScoreTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          iconWidget: SvgPicture.asset(
            AppAssets.cardComments,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppColors.textMuted,
              BlendMode.srcIn,
            ),
          ),
          label: '${site.commentCount}',
          color: AppColors.textMuted,
          onTap: onCommentsTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          iconWidget: const Icon(
            Icons.groups_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          label: site.coReporterNames.isNotEmpty
              ? '${site.coReporterNames.length}'
              : '${site.participantCount}',
          color: AppColors.textMuted,
          onTap: onParticipantsTap,
        ),
        const Spacer(),
        GestureDetector(
          onTap: onDistanceTap != null
              ? () {
                  AppHaptics.tap();
                  onDistanceTap!();
                }
              : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxs,
              horizontal: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.place_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '${site.distanceKm.toStringAsFixed(0)} km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: onDistanceTap != null
                            ? AppColors.primaryDark
                            : AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.iconWidget,
    required this.label,
    required this.color,
    this.onTap,
  });

  final Widget iconWidget;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: AppSpacing.xs,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          iconWidget,
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.chipLabel.copyWith(color: color),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          AppHaptics.tap();
          onTap!();
        },
        behavior: HitTestBehavior.opaque,
        child: chip,
      );
    }
    return chip;
  }
}
