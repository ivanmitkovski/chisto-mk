import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/domain/models/weekly_rankings_result.dart';

class WeeklyCurrentUserCard extends StatelessWidget {
  const WeeklyCurrentUserCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final WeeklyLeaderboardEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panelBackground,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
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
                  Icons.person_outline_rounded,
                  color: AppColors.primaryDark,
                  size: AppSpacing.iconLg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          context.l10n.profileWeeklyRankingsYouRank(entry.rank),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.radiusSm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusCircle,
                            ),
                          ),
                          child: Text(
                            context.l10n.profileWeeklyRankingsYouBadge,
                            style: AppTypography.badgeLabel.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.profileWeeklyRankingsPtsThisWeek(
                        entry.weeklyPoints,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
