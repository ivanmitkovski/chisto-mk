import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_recent_queries_shelf.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class RecentSearchesShelf extends StatelessWidget {
  const RecentSearchesShelf({
    super.key,
    required this.recentSearches,
    required this.onSearchTap,
  });

  final List<String> recentSearches;
  final ValueChanged<String> onSearchTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return AppRecentQueriesShelf(
      title: context.l10n.eventsFeedRecentSearches,
      queries: recentSearches,
      onQueryTap: onSearchTap,
      titleStyle: AppTypography.eventsMicroSectionHeading(textTheme),
    );
  }
}
