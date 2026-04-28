import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Placeholder rows while site comments bootstrap; shimmer respects reduce motion.
class CommentsRouteLoadingSkeleton extends StatefulWidget {
  const CommentsRouteLoadingSkeleton({super.key});

  @override
  State<CommentsRouteLoadingSkeleton> createState() =>
      _CommentsRouteLoadingSkeletonState();
}

class _CommentsRouteLoadingSkeletonState
    extends State<CommentsRouteLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: AppMotion.loadingOverlayLoop,
    );
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppMotion.syncRepeatingShimmer(_shimmer, context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) {
        return AnimatedBuilder(
          animation: _shimmer,
          builder: (BuildContext context, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ShimmerDisc(t: _shimmer.value),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _ShimmerLine(
                        width: double.infinity,
                        height: 12,
                        radius: 6,
                        t: _shimmer.value,
                      ),
                      const SizedBox(height: 6),
                      _ShimmerLine(
                        width: index.isEven ? 220.0 : 180.0,
                        height: 12,
                        radius: 6,
                        t: _shimmer.value,
                      ),
                      const SizedBox(height: 6),
                      _ShimmerLine(
                        width: 140,
                        height: 10,
                        radius: 5,
                        t: _shimmer.value,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ShimmerDisc extends StatelessWidget {
  const _ShimmerDisc({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return _ShimmerMask(
      t: t,
      radius: 18,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFE8E8E8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({
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
    return _ShimmerMask(
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

class _ShimmerMask extends StatelessWidget {
  const _ShimmerMask({
    required this.t,
    required this.radius,
    required this.child,
  });

  final double t;
  final double radius;
  final Widget child;

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
