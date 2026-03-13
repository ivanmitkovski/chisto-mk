import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class EventSuccessDialog extends StatefulWidget {
  const EventSuccessDialog({
    super.key,
    required this.title,
    required this.siteName,
  });

  final String title;
  final String siteName;

  @override
  State<EventSuccessDialog> createState() => _EventSuccessDialogState();
}

class _EventSuccessDialogState extends State<EventSuccessDialog>
    with TickerProviderStateMixin {
  late final AnimationController _containerController;
  late final AnimationController _checkController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _containerController = AnimationController(
      vsync: this,
      duration: AppMotion.emphasizedDuration,
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _containerController,
      curve: AppMotion.spring,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _containerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: AppMotion.emphasized,
    );

    _containerController.forward().then((_) {
      _checkController.forward();
      AppHaptics.success();
    });
  }

  @override
  void dispose() {
    _containerController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(28),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _checkAnimation,
                        builder: (BuildContext context, Widget? child) {
                          return CustomPaint(
                            size: const Size(36, 36),
                            painter: _CheckPainter(
                              progress: _checkAnimation.value,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Event created',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${widget.title} at ${widget.siteName} is ready. Share it with your community to get volunteers on board.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      AppHaptics.tap();
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: const Text(
                      'Open event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.42, size.height * 0.72)
      ..lineTo(size.width * 0.8, size.height * 0.28);

    final Iterable<ui.PathMetric> metrics = path.computeMetrics();
    for (final ui.PathMetric metric in metrics) {
      final Path extracted = metric.extractPath(
        0,
        metric.length * math.min(progress, 1.0),
      );
      canvas.drawPath(extracted, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => oldDelegate.progress != progress;
}
