import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class FeedSkeletonCard extends StatefulWidget {
  const FeedSkeletonCard({super.key});

  @override
  State<FeedSkeletonCard> createState() => _FeedSkeletonCardState();
}

class _FeedSkeletonCardState extends State<FeedSkeletonCard>
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
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ShimmerBox(width: double.infinity, height: 190, radius: 0, t: t),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _ShimmerBox(width: 24, height: 24, radius: 12, t: t),
                        const SizedBox(width: 4),
                        _ShimmerBox(width: 28, height: 12, radius: 6, t: t),
                        const SizedBox(width: 14),
                        _ShimmerBox(width: 24, height: 24, radius: 12, t: t),
                        const SizedBox(width: 4),
                        _ShimmerBox(width: 28, height: 12, radius: 6, t: t),
                        const SizedBox(width: 14),
                        _ShimmerBox(width: 24, height: 24, radius: 12, t: t),
                        const SizedBox(width: 4),
                        _ShimmerBox(width: 28, height: 12, radius: 6, t: t),
                        const Spacer(),
                        _ShimmerBox(width: 24, height: 24, radius: 12, t: t),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ShimmerBox(width: 180, height: 18, radius: 9, t: t),
                    const SizedBox(height: AppSpacing.sm),
                    _ShimmerBox(width: double.infinity, height: 14, radius: 7, t: t),
                    const SizedBox(height: AppSpacing.xs),
                    _ShimmerBox(width: 220, height: 14, radius: 7, t: t),
                    const SizedBox(height: AppSpacing.md),
                    _ShimmerBox(width: double.infinity, height: 44, radius: 14, t: t),
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
