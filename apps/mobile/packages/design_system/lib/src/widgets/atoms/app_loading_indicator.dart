import 'package:design_system/src/theme/app_colors.dart';
import 'package:flutter/material.dart';

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
    this.value,
  });

  final AppLoadingIndicatorSize size;
  final Color? color;

  /// When set, renders a determinate ring (e.g. image decode / upload).
  final double? value;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? AppColors.primary;
    final double? resolvedValue = value;
    if (MediaQuery.disableAnimationsOf(context) && resolvedValue == null) {
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
        value: resolvedValue,
        strokeWidth: size.strokeWidth,
        color: effectiveColor,
      ),
    );
  }
}

/// Thin progress bar for map/list top progress and determinate uploads.
class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({
    super.key,
    this.color,
    this.value,
    this.minHeight = 3,
    this.backgroundColor,
    this.valueColor,
  });

  final Color? color;
  final double? value;
  final double minHeight;
  final Color? backgroundColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value,
      minHeight: minHeight,
      color: valueColor ?? color ?? AppColors.primary,
      backgroundColor:
          backgroundColor ?? AppColors.divider.withValues(alpha: 0.35),
    );
  }
}
