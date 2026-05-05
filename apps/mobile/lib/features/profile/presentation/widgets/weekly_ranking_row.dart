import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/domain/models/weekly_rankings_result.dart';

class WeeklyRankingRow extends StatelessWidget {
  const WeeklyRankingRow({super.key, required this.entry});

  final WeeklyLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final bool isTopThree = entry.rank <= 3;
    final bool isCurrentUser = entry.isCurrentUser;
    final String initial = entry.displayName.isNotEmpty
        ? entry.displayName[0].toUpperCase()
        : '?';

    IconData? leadingIcon;
    Color iconColor = AppColors.textMuted;
    if (entry.rank == 1) {
      leadingIcon = Icons.emoji_events_rounded;
      iconColor = AppColors.accentWarning;
    } else if (entry.rank == 2) {
      leadingIcon = Icons.emoji_events_rounded;
      iconColor = AppColors.textMuted;
    } else if (entry.rank == 3) {
      leadingIcon = Icons.emoji_events_rounded;
      iconColor = AppColors.accentWarningDark;
    }

    final Color backgroundColor = isCurrentUser
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.panelBackground;
    final Color borderColor = isCurrentUser
        ? AppColors.primary.withValues(alpha: 0.4)
        : AppColors.divider.withValues(alpha: 0.9);

    return Semantics(
      label: context.l10n.profileWeeklyRankingsRowSemantic(
        entry.rank,
        entry.displayName,
        entry.weeklyPoints,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: AppSpacing.xl,
              child: Center(
                child: isTopThree && leadingIcon != null
                    ? Icon(
                        leadingIcon,
                        size: AppSpacing.iconMd,
                        color: iconColor,
                      )
                    : Text(
                        '${entry.rank}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: AppSpacing.radius18,
              backgroundColor: AppColors.inputFill,
              child: Text(
                initial,
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight:
                          isCurrentUser ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${entry.weeklyPoints}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
