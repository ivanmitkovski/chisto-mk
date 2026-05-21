import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class NotificationDayHeaderDelegate extends SliverPersistentHeaderDelegate {
  NotificationDayHeaderDelegate({required this.title});

  final String title;

  static const double extent = 36;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: AppColors.appBackground.withValues(
        alpha: overlapsContent ? 0.96 : 1,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant NotificationDayHeaderDelegate oldDelegate) {
    return oldDelegate.title != title;
  }
}
