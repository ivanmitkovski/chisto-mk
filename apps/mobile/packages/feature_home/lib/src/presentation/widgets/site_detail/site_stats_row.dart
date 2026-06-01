import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/widgets/site_card/site_upvote_affordance.dart';
import 'package:flutter/material.dart';

class SiteStatsRow extends StatelessWidget {
  const SiteStatsRow({
    super.key,
    required this.site,
    this.isUpvotePending = false,
    this.onUpvoteTap,
    this.onScoreTap,
    this.onCommentsTap,
    this.onParticipantsTap,
    this.onShareTap,
    this.onDistanceTap,
  });

  final PollutionSite site;
  final bool isUpvotePending;
  final Future<void> Function()? onUpvoteTap;
  final VoidCallback? onScoreTap;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onParticipantsTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onDistanceTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: <Widget>[
                if (onUpvoteTap != null)
                  SiteUpvoteAffordance(
                    variant: SiteUpvoteAffordanceVariant.statChip,
                    isUpvoted: site.isUpvotedByMe,
                    isBusy: isUpvotePending,
                    count: site.score,
                    countTextStyle: AppTypography.chipLabel(textTheme),
                    semanticsLabel: site.isUpvotedByMe
                        ? context.l10n.siteCardSemanticRemoveUpvote(site.title)
                        : context.l10n.siteCardSemanticUpvote(site.title),
                    semanticsLongPressHint:
                        context.l10n.siteUpvoteLongPressOpensSupporters,
                    onPressed: onUpvoteTap,
                    onLongPress: onScoreTap,
                  )
                else
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
                const SizedBox(width: AppSpacing.sm),
                _StatChip(
                  iconWidget: const Icon(
                    Icons.share_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  label: '${site.shareCount}',
                  color: AppColors.textMuted,
                  semanticsLabel: context.l10n.siteDetailSemanticShareCount(
                    site.shareCount,
                  ),
                  onTap: onShareTap,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: onDistanceTap != null
              ? () {
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
                      ? _formatDistance(context, site.distanceKm)
                      : context.l10n.commonNotAvailable,
                  style: AppTypography.chipLabel(textTheme).copyWith(
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

String _formatDistance(BuildContext context, double km) {
  final AppLocalizations l10n = context.l10n;
  return DistanceFormatter.formatCommonUnitKm(
    km,
    _CommonUnitDistanceLabels(l10n),
  );
}

class _CommonUnitDistanceLabels implements CommonUnitDistanceLabels {
  _CommonUnitDistanceLabels(this.l10n);

  final AppLocalizations l10n;

  @override
  String metersWithUnit(int meters) =>
      '$meters ${l10n.commonDistanceMetersUnit}';

  @override
  String kilometersWithUnit(String formattedKm) =>
      '$formattedKm ${l10n.commonDistanceKilometersUnit}';
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.iconWidget,
    required this.label,
    required this.color,
    this.semanticsLabel,
    this.onTap,
  });

  final Widget iconWidget;
  final String label;
  final Color color;
  final String? semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        boxShadow: AppShadows.softCard(Theme.of(context).colorScheme),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          iconWidget,
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.chipLabel(textTheme).copyWith(color: color),
          ),
        ],
      ),
    );

    final Widget wrapped = onTap != null
        ? GestureDetector(
            onTap: () {
              onTap!();
            },
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
