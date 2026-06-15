import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/feed_filter_sheet.dart';
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
      case FeedFilter.resolved:
        return l10n.feedEmptyResolvedTitle;
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
      case FeedFilter.resolved:
        return l10n.feedEmptyResolvedHint;
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
      case FeedFilter.resolved:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return AppEmptyState(
      icon: _icon(),
      iconKey: activeFilter,
      animateIconChanges: true,
      title: _title(context),
      subtitle: _hint(context),
      action: activeFilter != FeedFilter.all
          ? AppButton.secondary(
              label: l10n.feedShowAllSites,
              onPressed: onShowAllSites,
              expand: false,
            )
          : AppButton.outlined(
              label: l10n.feedPullToRefreshSemantic,
              onPressed: onRefresh,
              expand: false,
            ),
    );
  }
}
