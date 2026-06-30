import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/domain/models/weekly_rankings_result.dart';
import 'package:flutter/material.dart';

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
    final TextTheme textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.softCard(Theme.of(context).colorScheme),
      ),
      child: Material(
        color: AppColors.transparent,
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
                UserAvatarCircle(
                  displayName: entry.displayName,
                  imageUrl: entry.avatarUrl,
                  seed: entry.userId.isNotEmpty
                      ? entry.userId
                      : entry.displayName,
                  size: AppSpacing.xxl,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            context.l10n.profileWeeklyRankingsYouRank(
                              entry.rank,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
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
                              style: AppTypography.badgeLabel(textTheme)
                                  .copyWith(
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
                        style: AppTypographySurfaces.homeMutedCaption(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
