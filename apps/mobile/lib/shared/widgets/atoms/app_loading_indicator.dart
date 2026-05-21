import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

enum AppLoadingIndicatorSize {
  sm(20, 2),
  md(24, 2.5),
  lg(32, 3);

  const AppLoadingIndicatorSize(this.dimension, this.strokeWidth);

  final double dimension;
  final double strokeWidth;
}

/// Branded progress spinner — use instead of raw [CircularProgressIndicator] in features.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = AppLoadingIndicatorSize.md,
    this.color,
  });

  final AppLoadingIndicatorSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? AppColors.primary;
    if (MediaQuery.disableAnimationsOf(context)) {
      return SizedBox(
        width: size.dimension,
        height: size.dimension,
        child: CircularProgressIndicator(
          value: 0.35,
          strokeWidth: size.strokeWidth,
          color: effectiveColor,
        ),
      );
    }
    return SizedBox(
      width: size.dimension,
      height: size.dimension,
      child: CircularProgressIndicator(
        strokeWidth: size.strokeWidth,
        color: effectiveColor,
      ),
    );
  }
}

/// Thin indeterminate bar for map/list top progress.
class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      minHeight: 3,
      color: color ?? AppColors.primary,
      backgroundColor: AppColors.divider.withValues(alpha: 0.35),
    );
  }
}
