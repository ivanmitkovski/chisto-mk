import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

enum FeedFilter {
  all('All sites', 'Show all pollution reports', Icons.grid_view_rounded),
  urgent('Urgent', 'Requires immediate attention', Icons.warning_amber_rounded),
  nearby('Nearby', 'Closest to you first', Icons.near_me_rounded),
  mostVoted('Most voted', 'By community support', Icons.trending_up_rounded),
  recent('Recent', 'Newest reports first', Icons.schedule_rounded);

  const FeedFilter(this.label, this.subtitle, this.icon);
  final String label;
  final String subtitle;
  final IconData icon;
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
                'Filter feed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how to sort pollution reports',
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
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              color: AppColors.inputFill.withValues(alpha: 0.6),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryDark.withValues(alpha: 0.12)
                        : AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primaryDark.withValues(alpha: 0.3)
                          : AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    filter.icon,
                    size: 18,
                    color: isActive
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        filter.label,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
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
                                ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 20,
                    color: AppColors.primaryDark,
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
