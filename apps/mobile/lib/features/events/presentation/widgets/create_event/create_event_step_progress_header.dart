import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

/// Pinned sliver header: step label + progress for the create-event flow.
class CreateEventStepProgressDelegate extends SliverPersistentHeaderDelegate {
  CreateEventStepProgressDelegate({required this.steps});

  final int steps;

  static const double extent = 40;

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
      color: AppColors.appBackground,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.06),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Text(
                context.l10n.createEventStepProgress(steps),
                style: AppTypography.eventsListCardMeta(
                  Theme.of(context).textTheme,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  child: LinearProgressIndicator(
                    value: steps / 5,
                    minHeight: 4,
                    backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CreateEventStepProgressDelegate oldDelegate) {
    return oldDelegate.steps != steps;
  }
}
