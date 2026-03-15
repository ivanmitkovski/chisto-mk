import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class GalleryPageIndicators extends StatelessWidget {
  const GalleryPageIndicators({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    this.activeColor = AppColors.white,
    this.inactiveOpacity = 0.34,
    this.maxVisible = 5,
  });

  final int currentIndex;
  final int totalCount;
  final Color activeColor;
  final double inactiveOpacity;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final int visibleCount = totalCount <= maxVisible ? totalCount : maxVisible;
    final int halfWindow = visibleCount ~/ 2;
    int start = 0;
    if (totalCount > visibleCount) {
      start = currentIndex - halfWindow;
      if (start < 0) {
        start = 0;
      }
      if (start > totalCount - visibleCount) {
        start = totalCount - visibleCount;
      }
    }
    final int end = start + visibleCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(visibleCount, (int localIndex) {
        final int index = start + localIndex;
        final bool isActive = index == currentIndex;
        final bool isEdgeDot =
            totalCount > visibleCount && (index == start || index == end - 1);
        return AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasized,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs / 2),
          width: isActive ? AppSpacing.radius18 : (isEdgeDot ? AppSpacing.sheetHandleHeight : AppSpacing.xs),
          height: AppSpacing.sheetHandleHeight,
          decoration: BoxDecoration(
            color: activeColor.withValues(
              alpha: isActive ? 0.96 : inactiveOpacity,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
          ),
        );
      }),
    );
  }
}
