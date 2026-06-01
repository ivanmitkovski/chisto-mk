import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/feed_filter_sheet.dart';
import 'package:flutter/material.dart';

/// Horizontal filter chips for the pollution feed (scrolls with the list).
class FeedFilterBar extends StatelessWidget {
  const FeedFilterBar({
    super.key,
    required this.activeFilter,
    required this.onFilterSelected,
    this.onMoreFiltersTap,
  });

  final FeedFilter activeFilter;
  final ValueChanged<FeedFilter> onFilterSelected;
  final VoidCallback? onMoreFiltersTap;

  @override
  Widget build(BuildContext context) {
    return AppFilterPillBar<FeedFilter>(
      variant: AppFilterPillVariant.feedChip,
      items: <FilterPillItem<FeedFilter>>[
        for (final FeedFilter filter in FeedFilter.values)
          FilterPillItem<FeedFilter>(
            value: filter,
            label: filter.displayName(context.l10n),
            semanticsLabel: context.l10n.feedFilterSemantic(
              filter.displayName(context.l10n),
            ),
          ),
      ],
      selected: activeFilter,
      onSelected: onFilterSelected,
      trailing: onMoreFiltersTap == null
          ? null
          : IconButton(
              tooltip: context.l10n.feedMoreFiltersTooltip,
              onPressed: onMoreFiltersTap,
              icon: const Icon(Icons.tune_rounded, size: 22),
              color: AppColors.textMuted,
            ),
    );
  }
}
