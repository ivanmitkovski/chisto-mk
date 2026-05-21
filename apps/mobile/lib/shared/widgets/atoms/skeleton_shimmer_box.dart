import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

/// Pulse-driven placeholder bar used by screen skeletons ([ProfileScreenSkeleton], etc.).
///
/// [t] is typically [AnimationController.value] in \[0,1\]. When [baseTint] is set,
/// [tintPulseBoost] adds a subtle animated alpha (defaults to profile skeleton rows;
/// use a higher boost for high-contrast overlays e.g. hero scrim).
class SkeletonShimmerBox extends StatelessWidget {
  const SkeletonShimmerBox({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
    required this.t,
    this.baseTint,
    this.tintPulseBoost = 0.02,
  });

  final double width;
  final double height;
  final double radius;
  final double t;
  final Color? baseTint;

  /// Multiplied by [t]'s pulse and added to alpha when [baseTint] is non-null.
  final double tintPulseBoost;

  @override
  Widget build(BuildContext context) {
    final double pulse = 0.5 + 0.5 * (1 - (2 * t - 1).abs());
    final Color base = baseTint ?? AppColors.textMuted;
    final double opacity = 0.06 + 0.04 * pulse;
    final double boost = baseTint != null ? tintPulseBoost * pulse : 0.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base.withValues(alpha: opacity + boost),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
