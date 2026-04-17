import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class ReportCardSkeleton extends StatefulWidget {
  const ReportCardSkeleton({super.key});

  @override
  State<ReportCardSkeleton> createState() => _ReportCardSkeletonState();
}

class _ReportCardSkeletonState extends State<ReportCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppMotion.syncRepeatingShimmer(_shimmer, context);
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
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.divider, width: 0.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ShimmerBox(
                  width: 72,
                  height: 72,
                  radius: AppSpacing.radiusMd,
                  t: t,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _ShimmerBox(width: 52, height: 18, radius: 9, t: t),
                          const SizedBox(width: AppSpacing.xs),
                          _ShimmerBox(width: 64, height: 18, radius: 9, t: t),
                          const Spacer(),
                          _ShimmerBox(width: 20, height: 20, radius: 10, t: t),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _ShimmerBox(width: 88, height: 18, radius: 9, t: t),
                      const SizedBox(height: AppSpacing.xs),
                      _ShimmerBox(
                        width: double.infinity,
                        height: 16,
                        radius: 8,
                        t: t,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      _ShimmerBox(
                        width: double.infinity,
                        height: 12,
                        radius: 6,
                        t: t,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: <Widget>[
                          _ShimmerBox(width: 14, height: 14, radius: 7, t: t),
                          const SizedBox(width: AppSpacing.xxs),
                          _ShimmerBox(
                            width: 120,
                            height: 12,
                            radius: 6,
                            t: t,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    final double opacity =
        0.06 + 0.04 * (0.5 + 0.5 * (1 - (2 * t - 1).abs()));

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
