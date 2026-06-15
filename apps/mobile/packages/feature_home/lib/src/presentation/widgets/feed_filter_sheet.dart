import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum FeedFilter { all, urgent, nearby, mostVoted, recent, saved, resolved }

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
      case FeedFilter.resolved:
        return l10n.feedFilterResolvedName;
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
      case FeedFilter.resolved:
        return l10n.feedFilterResolvedDesc;
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
    return AppSheetScaffold(
      title: l10n.feedFiltersSheetTitle,
      subtitle: l10n.feedFiltersSheetSubtitle,
      trailing: AppCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: l10n.commonClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;
    final String name = filter.displayName(l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
                          style: AppTypography.cardTitle(textTheme).copyWith(
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          filter.description(l10n),
                          style: AppTypography.cardSubtitle(
                            textTheme,
                          ).copyWith(color: AppColors.textMuted),
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
