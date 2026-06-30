import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/domain/models/profile_user.dart';
import 'package:feature_profile/src/presentation/utils/profile_level_tier.dart';
import 'package:flutter/material.dart';

class PointsHistorySummaryStrip extends StatelessWidget {
  const PointsHistorySummaryStrip({super.key, required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
            ),
            child: Icon(
              profileTierIcon(user.levelTierKey),
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
                  profileMilestoneTierTitle(
                    context,
                    level: user.level,
                    levelTierKey: user.levelTierKey,
                    levelDisplayName: user.levelDisplayName,
                  ),
                  style: AppTypographySurfaces.profilePointsSummaryValue(
                    Theme.of(context).textTheme,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.profileLifetimeXpOnBar(user.totalPointsEarned),
                  style: AppTypographySurfaces.homeMutedCaption(
                    Theme.of(context).textTheme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
