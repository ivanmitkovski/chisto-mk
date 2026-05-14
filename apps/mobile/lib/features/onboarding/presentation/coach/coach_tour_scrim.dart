import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Dims the shell with an optional rounded cutout (used by [CoachTourHost] and tests).
class CoachTourScrimPainter extends CustomPainter {
  CoachTourScrimPainter({
    required this.holeRectLocal,
    required this.scrimColor,
    this.vignetteStrength = 0,
  });

  final Rect? holeRectLocal;
  final Color scrimColor;

  /// 0 = none; 1 = subtle edge darkening toward the cutout (low cost vs blur).
  final double vignetteStrength;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()..color = scrimColor;
    if (holeRectLocal == null || holeRectLocal!.isEmpty) {
      canvas.drawRect(Offset.zero & size, fill);
      return;
    }
    final Rect inflated = holeRectLocal!.inflate(10);
    final RRect rrect = RRect.fromRectAndRadius(
      inflated,
      const Radius.circular(AppSpacing.radiusMd),
    );
    final Path outer = Path()..addRect(Offset.zero & size);
    final Path inner = Path()..addRRect(rrect);
    final Path combined = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(combined, fill);

    final double v = vignetteStrength.clamp(0.0, 1.0);
    if (v > 0.001) {
      final Paint edge = Paint()
        ..color = Colors.black.withValues(alpha: 0.14 * v)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawRRect(rrect, edge);
    }
  }

  @override
  bool shouldRepaint(covariant CoachTourScrimPainter oldDelegate) {
    return oldDelegate.holeRectLocal != holeRectLocal ||
        oldDelegate.scrimColor != scrimColor ||
        oldDelegate.vignetteStrength != vignetteStrength;
  }
}

/// Soft accent ring around the spotlight hole (when reduce motion is off).
class CoachTourHoleRingPainter extends CustomPainter {
  CoachTourHoleRingPainter({
    required this.holeRectLocal,
    required this.ringColor,
    this.strokeWidth = 2,
  });

  final Rect? holeRectLocal;
  final Color ringColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (holeRectLocal == null || holeRectLocal!.isEmpty) {
      return;
    }
    final Rect inflated = holeRectLocal!.inflate(10);
    final RRect rrect = RRect.fromRectAndRadius(
      inflated,
      const Radius.circular(AppSpacing.radiusMd),
    );
    final Paint p = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, p);
  }

  @override
  bool shouldRepaint(covariant CoachTourHoleRingPainter oldDelegate) {
    return oldDelegate.holeRectLocal != holeRectLocal ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
