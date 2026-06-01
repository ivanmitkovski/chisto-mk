import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/domain/models/points_history_page.dart';
import 'package:feature_profile/src/presentation/utils/profile_level_tier.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PointsHistoryMilestoneChip extends StatelessWidget {
  const PointsHistoryMilestoneChip({super.key, required this.milestone});

  final PointsHistoryMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final String title = profileMilestoneTierTitle(
      context,
      level: milestone.level,
      levelTierKey: milestone.levelTierKey,
      levelDisplayName: milestone.levelDisplayName,
    );
    final String loc = Localizations.localeOf(context).toString();
    final String when = DateFormat.MMMd(
      loc,
    ).format(milestone.reachedAt.toLocal());

    return Semantics(
      container: true,
      label: '$title, $when',
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radius18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.primary.withValues(alpha: 0.14),
              AppColors.primaryDark.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          boxShadow: AppShadows.softCard(Theme.of(context).colorScheme),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
              ),
              child: Text(
                context.l10n.profilePointsHistoryLevelUpBadge,
                style: AppTypographySurfaces.profileMilestoneLevelBadge(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypographySurfaces.profileMilestoneTitle(
                Theme.of(context).textTheme,
              ),
            ),
            Text(
              when,
              style: AppTypographySurfaces.profileMilestoneChipMeta(
                Theme.of(context).textTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
