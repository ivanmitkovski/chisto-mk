import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_sheet.dart';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (final FeedFilter filter in FeedFilter.values) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Semantics(
                  button: true,
                  selected: activeFilter == filter,
                  excludeSemantics: true,
                  label: context.l10n.feedFilterSemantic(
                    filter.displayName(context.l10n),
                  ),
                  child: FilterChip(
                    label: Text(filter.displayName(context.l10n)),
                    selected: activeFilter == filter,
                    showCheckmark: false,
                    onSelected: (_) => onFilterSelected(filter),
                    selectedColor: AppColors.primaryDark.withValues(alpha: 0.12),
                    labelStyle: AppTypography.chipLabel.copyWith(
                      color: activeFilter == filter
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      fontWeight: activeFilter == filter
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: activeFilter == filter
                          ? AppColors.primaryDark.withValues(alpha: 0.35)
                          : AppColors.divider,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                  ),
                ),
              ),
            ],
            if (onMoreFiltersTap != null)
              IconButton(
                tooltip: context.l10n.feedMoreFiltersTooltip,
                onPressed: onMoreFiltersTap,
                icon: const Icon(Icons.tune_rounded, size: 22),
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
