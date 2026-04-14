import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class SiteStatsRow extends StatelessWidget {
  const SiteStatsRow({
    super.key,
    required this.site,
    this.isUpvotePending = false,
    this.upvoteScale = 1,
    this.onUpvoteTap,
    this.onScoreTap,
    this.onCommentsTap,
    this.onParticipantsTap,
    this.onDistanceTap,
  });

  final PollutionSite site;
  final bool isUpvotePending;
  final double upvoteScale;
  final VoidCallback? onUpvoteTap;
  final VoidCallback? onScoreTap;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onParticipantsTap;
  final VoidCallback? onDistanceTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: <Widget>[
                _StatChip(
                  iconWidget: Icon(
                    site.isUpvotedByMe
                        ? Icons.arrow_circle_up_rounded
                        : Icons.arrow_circle_up_outlined,
                    size: 16,
                    color: site.isUpvotedByMe
                        ? AppColors.primaryDark
                        : AppColors.textMuted,
                  ),
                  label: '${site.score}',
                  color: site.isUpvotedByMe
                      ? AppColors.primaryDark
                      : AppColors.textMuted,
                  isPending: isUpvotePending,
                  scale: upvoteScale,
                  onTap: onUpvoteTap,
                  onLongPress: onScoreTap,
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatChip(
                  iconWidget: const Icon(
                    Icons.mode_comment_outlined,
                    size: 16,
                    color: AppColors.textMuted,
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
                  label: '${site.siteParticipantStatsBadgeValue}',
                  color: AppColors.textMuted,
                  semanticsLabel: context.l10n.siteParticipantStatsSemantic(
                    site.siteParticipantStatsBadgeValue,
                  ),
                  onTap: onParticipantsTap,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
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
                  site.distanceKm >= 0
                      ? _formatDistance(site.distanceKm)
                      : '—',
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

String _formatDistance(double km) {
  if (km < 1) {
    final int meters = (km * 1000).round().clamp(1, 999);
    return '$meters m';
  }
  if (km < 10) {
    return '${km.toStringAsFixed(1)} km';
  }
  return '${km.toStringAsFixed(0)} km';
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.iconWidget,
    required this.label,
    required this.color,
    this.semanticsLabel,
    this.isPending = false,
    this.scale = 1,
    this.onTap,
    this.onLongPress,
  });

  final Widget iconWidget;
  final String label;
  final Color color;
  final String? semanticsLabel;
  final bool isPending;
  final double scale;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final Widget chip = AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: scale,
      child: AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isPending ? 0.6 : 1,
      child: Container(
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
    )));

    final Widget wrapped = onTap != null
        ? GestureDetector(
            onTap: () {
              AppHaptics.tap();
              onTap!();
            },
            onLongPress: onLongPress,
            behavior: HitTestBehavior.opaque,
            child: chip,
          )
        : chip;

    return Semantics(
      label: semanticsLabel ?? label,
      button: onTap != null,
      child: wrapped,
    );
  }
}
