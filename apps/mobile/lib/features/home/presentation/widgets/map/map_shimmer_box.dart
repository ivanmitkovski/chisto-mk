import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

/// Tone helpers for map loading skeleton shards.
abstract final class MapShimmerTone {
  static Color shimmerGradientFill({
    required bool dark,
    required double opacityBase,
    required double t,
    required double wave,
  }) {
    final double blend =
        opacityBase + 0.04 * wave * (0.5 + 0.5 * (1 - (2 * t - 1).abs()));
    return dark
        ? AppColors.white.withValues(alpha: blend.clamp(0.02, 0.18))
        : AppColors.textMuted.withValues(alpha: blend.clamp(0.04, 0.22));
  }
}

/// Lightweight opacity-pulse slab for tile-grid skeleton cells.
class MapSkeletonPulseBox extends StatelessWidget {
  const MapSkeletonPulseBox({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
    required this.t,
    required this.dark,
    this.phase = 0,
  });

  final double width;
  final double height;
  final double radius;
  final double t;
  final bool dark;
  /// 0..1 row+col-derived phase for diagonal ripple.
  final double phase;

  @override
  Widget build(BuildContext context) {
    final double wave = math.sin((t + phase) * math.pi * 2).abs();
    final double opacity = dark
        ? 0.038 + 0.05 * wave
        : 0.055 + 0.065 * wave;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dark
            ? AppColors.white.withValues(alpha: opacity)
            : AppColors.textMuted.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Shader sweep for toolbar / FAB ghost chrome.
class MapSkeletonShimmerBox extends StatelessWidget {
  const MapSkeletonShimmerBox({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
    required this.t,
    required this.dark,
  });

  final double width;
  final double height;
  final double radius;
  final double t;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final double travel = (t * 2) - 0.5;
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment(-1.0 + travel, -0.3),
          end: Alignment(1.0 + travel, 0.3),
          colors: dark
              ? <Color>[
                  AppColors.white.withValues(alpha: 0.045),
                  AppColors.white.withValues(alpha: 0.12),
                  AppColors.white.withValues(alpha: 0.045),
                ]
              : <Color>[
                  AppColors.textMuted.withValues(alpha: 0.06),
                  AppColors.textMuted.withValues(alpha: 0.14),
                  AppColors.textMuted.withValues(alpha: 0.06),
                ],
          stops: const <double>[0.2, 0.5, 0.8],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: MapShimmerTone.shimmerGradientFill(
              dark: dark,
              opacityBase: dark ? 0.05 : 0.085,
              t: t,
              wave: 1,
            ),
          ),
        ),
      ),
    );
  }
}
