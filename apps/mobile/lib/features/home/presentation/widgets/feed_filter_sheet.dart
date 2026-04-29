import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

enum FeedFilter {
  all,
  urgent,
  nearby,
  mostVoted,
  recent,
  saved,
}

extension FeedFilterUi on FeedFilter {
  String displayName(AppLocalizations l10n) {
    switch (this) {
      case FeedFilter.all:
        return l10n.feedFilterAllName;
      case FeedFilter.urgent:
        return l10n.feedFilterUrgentName;
      case FeedFilter.nearby:
        return l10n.feedFilterNearbyName;
      case FeedFilter.mostVoted:
        return l10n.feedFilterMostVotedName;
      case FeedFilter.recent:
        return l10n.feedFilterRecentName;
      case FeedFilter.saved:
        return l10n.feedFilterSavedName;
    }
  }

  String description(AppLocalizations l10n) {
    switch (this) {
      case FeedFilter.all:
        return l10n.feedFilterAllDesc;
      case FeedFilter.urgent:
        return l10n.feedFilterUrgentDesc;
      case FeedFilter.nearby:
        return l10n.feedFilterNearbyDesc;
      case FeedFilter.mostVoted:
        return l10n.feedFilterMostVotedDesc;
      case FeedFilter.recent:
        return l10n.feedFilterRecentDesc;
      case FeedFilter.saved:
        return l10n.feedFilterSavedDesc;
    }
  }
}

class FeedFilterSheet extends StatelessWidget {
  const FeedFilterSheet({
    super.key,
    required this.activeFilter,
    required this.onSelected,
  });

  final FeedFilter activeFilter;
  final void Function(FeedFilter) onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: AppSpacing.sheetHandle,
                    height: AppSpacing.sheetHandleHeight,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.feedFiltersSheetTitle,
                  style: AppTypography.sheetTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.feedFiltersSheetSubtitle,
                  style: AppTypography.cardSubtitle.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...FeedFilter.values.map(
                  (FeedFilter filter) => _FilterTile(
                    filter: filter,
                    isActive: filter == activeFilter,
                    onTap: () => onSelected(filter),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.filter,
    required this.isActive,
    required this.onTap,
  });

  final FeedFilter filter;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String name = filter.displayName(l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.transparent,
        child: Semantics(
          button: true,
          selected: isActive,
          label: l10n.feedFilterSemantic(name),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                color: isActive
                    ? AppColors.primaryDark.withValues(alpha: 0.08)
                    : AppColors.inputFill.withValues(alpha: 0.55),
                border: Border.all(
                  color: isActive
                      ? AppColors.primaryDark.withValues(alpha: 0.22)
                      : AppColors.divider.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name,
                          style: AppTypography.cardTitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          filter.description(l10n),
                          style: AppTypography.cardSubtitle.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      size: 18,
                      color: AppColors.primaryDark,
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
