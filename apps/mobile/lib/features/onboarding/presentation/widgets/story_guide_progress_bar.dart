import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Minimal segmented progress (iOS-like capsules).
class StoryGuideProgressBar extends StatelessWidget {
  const StoryGuideProgressBar({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.reduceMotion,
  });

  final int count;
  final int currentIndex;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: List<Widget>.generate(count, (int i) {
          final bool filled = i <= currentIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i < count - 1 ? AppSpacing.xs : 0,
              ),
              child: AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : AppMotion.coachProgressSegment,
                curve: AppMotion.smooth,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.5),
                  color: filled ? AppColors.primary : AppColors.divider,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
