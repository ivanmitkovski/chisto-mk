import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class FeedSkeletonCard extends StatefulWidget {
  const FeedSkeletonCard({super.key});

  @override
  State<FeedSkeletonCard> createState() => _FeedSkeletonCardState();
}

class _FeedSkeletonCardState extends State<FeedSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: const <Color>[
                Color(0xFFEBECF0),
                Color(0xFFF5F6FA),
                Color(0xFFEBECF0),
              ],
              stops: <double>[
                (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                _shimmerController.value,
                (_shimmerController.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child!,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(color: AppColors.inputFill),
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
                      _SkeletonBox(width: 28, height: 28, isCircle: true),
                      const SizedBox(width: AppSpacing.sm),
                      _SkeletonBox(width: 28, height: 28, isCircle: true),
                      const SizedBox(width: AppSpacing.sm),
                      _SkeletonBox(width: 28, height: 28, isCircle: true),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SkeletonLine(widthFactor: 0.55),
                  const SizedBox(height: AppSpacing.sm),
                  _SkeletonLine(widthFactor: 0.85),
                  const SizedBox(height: AppSpacing.xs),
                  _SkeletonLine(widthFactor: 0.65),
                  const SizedBox(height: AppSpacing.lg),
                  _SkeletonLine(widthFactor: 1.0, height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, this.height = 12});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(height > 20 ? 12 : 999),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.isCircle = false,
  });

  final double width;
  final double height;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(6),
      ),
    );
  }
}
