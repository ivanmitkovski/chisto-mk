import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/theme/app_colors.dart';
import 'package:chisto_infrastructure/core/theme/app_spacing.dart';
import 'package:chisto_infrastructure/core/theme/app_typography.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/domain/models/weekly_rankings_result.dart';
import 'package:flutter/material.dart';

class WeeklyRankingRow extends StatelessWidget {
  const WeeklyRankingRow({super.key, required this.entry});

  final WeeklyLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isTopThree = entry.rank <= 3;
    final bool isCurrentUser = entry.isCurrentUser;

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

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
          boxShadow: AppShadows.softCard(colorScheme),
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
                        style: AppTypography.profileWeeklyRankSecondary(
                          Theme.of(context).textTheme,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            UserAvatarCircle(
              displayName: entry.displayName,
              imageUrl: entry.avatarUrl,
              seed: entry.userId.isNotEmpty
                  ? entry.userId
                  : entry.displayName,
              size: AppSpacing.radius18 * 2,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.profileWeeklyRankPrimary(
                  Theme.of(context).textTheme,
                  isCurrentUser: isCurrentUser,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${entry.weeklyPoints}',
              style: AppTypographySurfaces.profileWeeklyRankPoints(
                Theme.of(context).textTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
