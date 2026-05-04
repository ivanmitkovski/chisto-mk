import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ReportSubmittedCheckmarkPainter extends CustomPainter {
  ReportSubmittedCheckmarkPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final Paint paint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.4, size.height * 0.74)
      ..lineTo(size.width * 0.82, size.height * 0.26);

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
  bool shouldRepaint(ReportSubmittedCheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
