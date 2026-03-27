import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class FeedSkeletonCard extends StatelessWidget {
  const FeedSkeletonCard({
    super.key,
    required this.shimmerT,
  });

  final double shimmerT;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: AppSpacing.md,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: AppSpacing.lg,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double imageHeight = constraints.maxWidth * (9 / 16);
              return _ShimmerBox(
                width: double.infinity,
                height: imageHeight,
                radius: 0,
                t: shimmerT,
              );
            },
          ),
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
                    _ShimmerBox(width: 24, height: 24, radius: 12, t: shimmerT),
                    const SizedBox(width: 4),
                    _ShimmerBox(width: 28, height: 12, radius: 6, t: shimmerT),
                    const SizedBox(width: 14),
                    _ShimmerBox(width: 24, height: 24, radius: 12, t: shimmerT),
                    const SizedBox(width: 4),
                    _ShimmerBox(width: 28, height: 12, radius: 6, t: shimmerT),
                    const SizedBox(width: 14),
                    _ShimmerBox(width: 24, height: 24, radius: 12, t: shimmerT),
                    const SizedBox(width: 4),
                    _ShimmerBox(width: 28, height: 12, radius: 6, t: shimmerT),
                    const Spacer(),
                    _ShimmerBox(width: 24, height: 24, radius: 12, t: shimmerT),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _ShimmerBox(width: 180, height: 18, radius: 9, t: shimmerT),
                const SizedBox(height: AppSpacing.sm),
                _ShimmerBox(
                  width: double.infinity,
                  height: 14,
                  radius: 7,
                  t: shimmerT,
                ),
                const SizedBox(height: AppSpacing.xs),
                _ShimmerBox(width: 220, height: 14, radius: 7, t: shimmerT),
                const SizedBox(height: AppSpacing.md),
                _ShimmerBox(
                  width: double.infinity,
                  height: 44,
                  radius: 14,
                  t: shimmerT,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerGradient extends StatelessWidget {
  const _ShimmerGradient({
    required this.t,
    required this.child,
    required this.radius,
  });

  final double t;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        final double travel = (t * 2) - 0.5;
        return LinearGradient(
          begin: Alignment(-1.0 + travel, -0.3),
          end: Alignment(1.0 + travel, 0.3),
          colors: <Color>[
            AppColors.textMuted.withValues(alpha: 0.08),
            AppColors.textMuted.withValues(alpha: 0.18),
            AppColors.textMuted.withValues(alpha: 0.08),
          ],
          stops: const <double>[0.2, 0.5, 0.8],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
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
    return _ShimmerGradient(
      t: t,
      radius: radius,
      child: Container(
        width: width,
        height: height,
        color: AppColors.textMuted.withValues(alpha: 0.11),
      ),
    );
  }
}
