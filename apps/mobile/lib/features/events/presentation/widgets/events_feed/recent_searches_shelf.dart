import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

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
    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.eventsFeedRecentSearches,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentSearches.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (BuildContext context, int index) {
                final String query = recentSearches[index];
                return ActionChip(
                  avatar: const Icon(
                    CupertinoIcons.time,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  label: Text(query),
                  onPressed: () => onSearchTap(query),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
