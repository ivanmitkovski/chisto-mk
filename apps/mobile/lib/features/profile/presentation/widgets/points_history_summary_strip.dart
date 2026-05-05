import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/utils/profile_level_tier.dart';

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
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.9),
        ),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.profileLifetimeXpOnBar(user.totalPointsEarned),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
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
