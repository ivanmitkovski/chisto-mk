import 'package:flutter/material.dart';

// TODO: Wire to GET /rankings or GET /users/rankings when endpoint is available

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/data/profile_mock_data.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class WeeklyRankingsScreen extends StatefulWidget {
  const WeeklyRankingsScreen({super.key});

  @override
  State<WeeklyRankingsScreen> createState() => _WeeklyRankingsScreenState();
}

class _WeeklyRankingsScreenState extends State<WeeklyRankingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentUserRowKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentUser() {
    AppHaptics.tap();
    final BuildContext? rowContext = _currentUserRowKey.currentContext;
    if (rowContext == null) return;
    Scrollable.ensureVisible(
      rowContext,
      duration: AppMotion.emphasizedDuration,
      curve: AppMotion.decelerate,
      alignment: 0.3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<WeeklyRankingEntry> entries = ProfileMockData.weeklyRankings;

    WeeklyRankingEntry? currentUserEntry;
    try {
      currentUserEntry =
          entries.firstWhere((WeeklyRankingEntry e) => e.isCurrentUser);
    } catch (_) {
      currentUserEntry = null;
    }

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppBackButton(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Weekly rankings',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'See how you compare this week.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'This week\'s top supporters',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (currentUserEntry != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: _CurrentUserRankCard(
                  entry: currentUserEntry,
                  onTap: _scrollToCurrentUser,
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                controller: _scrollController,
                itemBuilder: (BuildContext context, int index) {
                  final WeeklyRankingEntry entry = entries[index];
                  if (entry.isCurrentUser) {
                    return KeyedSubtree(
                      key: _currentUserRowKey,
                      child: _RankingRow(entry: entry),
                    );
                  }
                  return _RankingRow(entry: entry);
                },
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                itemCount: entries.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentUserRankCard extends StatelessWidget {
  const _CurrentUserRankCard({
    required this.entry,
    required this.onTap,
  });

  final WeeklyRankingEntry entry;
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
                          'You are #${entry.position} this week',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
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
                            borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
                          ),
                          child: Text(
                            'You',
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
                      '${entry.points} pts collected this week',
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

// Intentionally left empty – top 3 is represented directly in the leaderboard rows.

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});

  final WeeklyRankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final bool isTopThree = entry.position <= 3;
    final bool isCurrentUser = entry.isCurrentUser;

    IconData? leadingIcon;
    Color iconColor = AppColors.textMuted;
    if (entry.position == 1) {
      leadingIcon = Icons.emoji_events_rounded;
      iconColor = AppColors.accentWarning;
    } else if (entry.position == 2) {
      leadingIcon = Icons.emoji_events_rounded;
      iconColor = AppColors.textMuted;
    } else if (entry.position == 3) {
      leadingIcon = Icons.emoji_events_rounded;
      iconColor = AppColors.accentWarningDark;
    }

    Color backgroundColor = isCurrentUser
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.panelBackground;
    Color borderColor = isCurrentUser
        ? AppColors.primary.withValues(alpha: 0.4)
        : AppColors.divider.withValues(alpha: 0.9);

    return Container(
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
                      '${entry.position}',
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
              entry.name.isNotEmpty ? entry.name[0] : '?',
              style: AppTypography.cardTitle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${entry.points}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

