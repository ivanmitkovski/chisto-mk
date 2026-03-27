import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

enum FeedFilter {
  all('All', 'Balanced feed ranking'),
  urgent('Urgent', 'High-priority incidents first'),
  nearby('Nearby', 'Closest reports around you'),
  mostVoted('Top support', 'Most community-backed'),
  recent('Recent', 'Newest reports first');

  const FeedFilter(this.label, this.subtitle);
  final String label;
  final String subtitle;
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
                'Feed filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how you want to browse reports',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.transparent,
        child: Semantics(
          button: true,
          selected: isActive,
          label: '${filter.label} filter',
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
                        filter.label,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        filter.subtitle,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
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
