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
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter feed',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg + 16,
              ),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: FeedFilter.values.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 2),
              itemBuilder: (BuildContext context, int index) {
                final FeedFilter filter = FeedFilter.values[index];
                final bool isActive = filter == activeFilter;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelected(filter),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 12,
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryDark.withValues(alpha: 0.12)
                                  : AppColors.inputFill,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              filter.icon,
                              size: 20,
                              color: isActive
                                  ? AppColors.primaryDark
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  filter.label,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: isActive
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  filter.subtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textMuted,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            const Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              size: 24,
                              color: AppColors.primaryDark,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
