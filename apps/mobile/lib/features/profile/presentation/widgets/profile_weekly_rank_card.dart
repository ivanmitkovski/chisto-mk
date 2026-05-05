import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';

/// Weekly leaderboard summary row on the profile home.
class ProfileWeeklyRankCard extends StatelessWidget {
  const ProfileWeeklyRankCard({
    super.key,
    required this.user,
    required this.onViewRankings,
  });

  final ProfileUser user;
  final VoidCallback onViewRankings;

  String _detailLine(BuildContext context) {
    if (user.weeklyRank != null && user.weeklyPoints > 0) {
      return context.l10n.profileMyWeeklyRankDetailRanked(
        user.weeklyRank!,
        user.weeklyPoints,
      );
    }
    if (user.weeklyPoints > 0) {
      return context.l10n.profileMyWeeklyRankDetailPointsOnly(
        user.weeklyPoints,
      );
    }
    return context.l10n.profileMyWeeklyRankNoPoints;
  }

  @override
  Widget build(BuildContext context) {
    final String detail = _detailLine(context);
    return Semantics(
      button: true,
      label:
          '${context.l10n.profileWeeklyRankCardSemantic}. $detail',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onViewRankings,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Container(
                    width: AppSpacing.xxl,
                    height: AppSpacing.xxl,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppSpacing.radius14),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.primaryDark,
                      size: AppSpacing.iconLg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          context.l10n.profileMyWeeklyRankTitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
