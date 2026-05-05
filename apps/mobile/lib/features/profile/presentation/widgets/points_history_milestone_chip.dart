import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/profile/domain/models/points_history_page.dart';
import 'package:chisto_mobile/features/profile/presentation/utils/profile_level_tier.dart';
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
    final String when = DateFormat.MMMd(loc).format(
      milestone.reachedAt.toLocal(),
    );

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
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      fontSize: 9,
                    ),
              ),
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
            ),
            Text(
              when,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
