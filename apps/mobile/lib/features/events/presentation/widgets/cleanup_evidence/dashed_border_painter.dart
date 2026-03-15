import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  final Color color;
  final double borderRadius;
  static const double _dashWidth = 6.0;
  static const double _dashGap = 4.0;
  static const double _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rRect);
    final List<ui.PathMetric> metrics = path.computeMetrics().toList();
    for (final ui.PathMetric metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double end =
            (distance + _dashWidth).clamp(0, metric.length).toDouble();
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance += _dashWidth + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      borderRadius != oldDelegate.borderRadius;
}
