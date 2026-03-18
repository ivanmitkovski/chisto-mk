import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({super.key, required this.visible});

  final bool visible;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Only animate when the overlay is actually visible to avoid
    // unnecessary work and to keep widget tests from hanging.
    if (widget.visible) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.visible && widget.visible) {
      _controller.repeat();
    } else if (oldWidget.visible && !widget.visible) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: widget.visible ? 1 : 0,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: ColoredBox(
            color: AppColors.overlay,
            child: Center(
              child: AnimatedScale(
                duration: AppMotion.medium,
                curve: AppMotion.smooth,
                scale: widget.visible ? 1 : 0.92,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 26,
                        offset: const Offset(0, AppSpacing.radius10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, Widget? child) {
                      final double t = _controller.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: 2 * math.pi * t,
                            child: SizedBox(
                              width: 74,
                              height: 74,
                              child: CustomPaint(
                                painter: _LoadingRingPainter(),
                              ),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: SvgPicture.asset(
                      AppAssets.brandGlyphWhite,
                      width: 52,
                      height: 60,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primaryDark,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 4;
    final Rect rect = Offset.zero & size;
    final Paint background = Paint()
      ..color = AppColors.inputBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Paint foreground = Paint()
      ..shader = SweepGradient(
        colors: <Color>[
          AppColors.primary.withValues(alpha: 0.0),
          AppColors.primary,
          AppColors.primaryDark,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final Offset center = rect.center;
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    canvas.drawCircle(center, radius, background);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.4,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _LoadingRingPainter oldDelegate) => false;
}
