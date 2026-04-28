import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_sheet.dart';
import 'package:flutter/material.dart';

class FeedEmptyState extends StatelessWidget {
  const FeedEmptyState({
    super.key,
    required this.activeFilter,
    required this.locationAvailable,
    required this.onShowAllSites,
    required this.onRefresh,
  });

  final FeedFilter activeFilter;
  final bool locationAvailable;
  final VoidCallback onShowAllSites;
  final VoidCallback onRefresh;

  String _title(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    switch (activeFilter) {
      case FeedFilter.urgent:
        return l10n.feedEmptyUrgentTitle;
      case FeedFilter.nearby:
        return locationAvailable
            ? l10n.feedEmptyNearbyTitleOnline
            : l10n.feedEmptyNearbyTitleOffline;
      case FeedFilter.mostVoted:
        return l10n.feedEmptyMostVotedTitle;
      case FeedFilter.recent:
        return l10n.feedEmptyRecentTitle;
      case FeedFilter.saved:
        return l10n.feedEmptySavedTitle;
      case FeedFilter.all:
        return l10n.feedEmptyAllTitle;
    }
  }

  String _hint(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    switch (activeFilter) {
      case FeedFilter.urgent:
        return l10n.feedEmptyUrgentHint;
      case FeedFilter.nearby:
        return locationAvailable
            ? l10n.feedEmptyNearbyHintOnline
            : l10n.feedEmptyNearbyHintOffline;
      case FeedFilter.mostVoted:
        return l10n.feedEmptyMostVotedHint;
      case FeedFilter.recent:
        return l10n.feedEmptyRecentHint;
      case FeedFilter.saved:
        return l10n.feedEmptySavedHint;
      case FeedFilter.all:
        return l10n.feedEmptyAllHint;
    }
  }

  IconData _icon() {
    switch (activeFilter) {
      case FeedFilter.all:
        return Icons.filter_alt_outlined;
      case FeedFilter.urgent:
        return Icons.warning_amber_rounded;
      case FeedFilter.nearby:
        return Icons.near_me_rounded;
      case FeedFilter.mostVoted:
        return Icons.trending_up_rounded;
      case FeedFilter.recent:
        return Icons.schedule_rounded;
      case FeedFilter.saved:
        return Icons.bookmark_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSwitcher(
              duration: AppMotion.fast,
              switchInCurve: AppMotion.emphasized,
              switchOutCurve: AppMotion.emphasized,
              child: Container(
                key: ValueKey<FeedFilter>(activeFilter),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Icon(
                  _icon(),
                  size: 30,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _title(context),
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _hint(context),
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateSubtitle.copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (activeFilter != FeedFilter.all)
              FilledButton.tonal(
                onPressed: onShowAllSites,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark.withValues(
                    alpha: 0.12,
                  ),
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: Text(context.l10n.feedShowAllSites),
              )
            else
              OutlinedButton(
                onPressed: onRefresh,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: Text(context.l10n.feedPullToRefreshSemantic),
              ),
          ],
        ),
      ),
    );
  }
}
