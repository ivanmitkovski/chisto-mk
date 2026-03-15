import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class EventCardSkeleton extends StatefulWidget {
  const EventCardSkeleton({super.key});

  @override
  State<EventCardSkeleton> createState() => _EventCardSkeletonState();
}

class _EventCardSkeletonState extends State<EventCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (BuildContext context, Widget? child) {
        final double t = _shimmer.value;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              _ShimmerBox(width: 72, height: 72, radius: 14, t: t),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _ShimmerBox(width: 100, height: 10, radius: 5, t: t),
                    const SizedBox(height: AppSpacing.sm),
                    _ShimmerBox(
                      width: double.infinity,
                      height: 14,
                      radius: 7,
                      t: t,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ShimmerBox(width: 140, height: 10, radius: 5, t: t),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.t,
  });

  final double width;
  final double height;
  final double radius;
  final double t;

  @override
  Widget build(BuildContext context) {
    final double opacity = 0.06 + 0.04 * (0.5 + 0.5 * (1 - (2 * t - 1).abs()));

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
