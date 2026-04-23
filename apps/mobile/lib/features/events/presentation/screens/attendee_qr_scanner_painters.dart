import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

/// Darkens the preview outside [scanRect] so the target area reads as one square.
class AttendeeQrDimOutsideScanPainter extends CustomPainter {
  AttendeeQrDimOutsideScanPainter({
    required this.scanRect,
    required this.overlayColor,
    this.holeRadius = 16,
  });

  final Rect scanRect;
  final Color overlayColor;
  final double holeRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Path outer = Path()..addRect(Offset.zero & size);
    final Path hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanRect, Radius.circular(holeRadius)),
      );
    final Path mask = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(mask, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(covariant AttendeeQrDimOutsideScanPainter oldDelegate) =>
      scanRect != oldDelegate.scanRect ||
      overlayColor != oldDelegate.overlayColor ||
      holeRadius != oldDelegate.holeRadius;
}

/// Solid rounded-rect outline + decorative QR-like dot field **inside** the square.
///
/// Finder patterns and timing strips read clearly; data area uses a light dither.
/// Inner radial wash + tiered opacity keeps the camera preview readable.
class AttendeeQrSquareScanFramePainter extends CustomPainter {
  AttendeeQrSquareScanFramePainter({
    required this.color,
    this.strokeWidth = 3,
    this.cornerRadius = 16,
  });

  final Color color;
  final double strokeWidth;
  final double cornerRadius;

  static const double _innerInset = 15;

  /// Standard QR finder pattern (7×7, `true` = dark module).
  static const List<List<bool>> _finder7 = <List<bool>>[
    <bool>[true, true, true, true, true, true, true],
    <bool>[true, false, false, false, false, false, true],
    <bool>[true, false, true, true, true, false, true],
    <bool>[true, false, true, true, true, false, true],
    <bool>[true, false, true, true, true, false, true],
    <bool>[true, false, false, false, false, false, true],
    <bool>[true, true, true, true, true, true, true],
  ];

  /// Returns whether the cell is “inked” and which visual tier to use.
  static AttendeeQrDotTier? _moduleTier(int row, int col, int rows, int cols) {
    if (cols >= 7 && rows >= 7) {
      if (row < 7 && col < 7) {
        return _finder7[row][col] ? AttendeeQrDotTier.finder : null;
      }
      if (row < 7 && col >= cols - 7) {
        return _finder7[row][col - (cols - 7)] ? AttendeeQrDotTier.finder : null;
      }
      if (row >= rows - 7 && col < 7) {
        return _finder7[row - (rows - 7)][col] ? AttendeeQrDotTier.finder : null;
      }
    }
    if (cols >= 14 && rows >= 14) {
      if (row == 6 && col >= 7 && col < cols - 7) {
        return (col - 7).isEven ? AttendeeQrDotTier.timing : null;
      }
      if (col == 6 && row >= 7 && row < rows - 7) {
        return (row - 7).isEven ? AttendeeQrDotTier.timing : null;
      }
    }
    if (((row * 17 + col * 31) & 7) < 3) {
      return AttendeeQrDotTier.data;
    }
    return null;
  }

  static void _paintInnerCornerAccents(
    Canvas canvas,
    RRect inner,
    Color accent,
  ) {
    final double inset = math.max(5, inner.width * 0.04);
    final double d = 2.2;
    final Paint p = Paint()
      ..isAntiAlias = true
      ..color = accent;
    void cornerDots(double lx, double ty) {
      canvas.drawCircle(Offset(lx, ty), d, p);
      canvas.drawCircle(Offset(lx + 5, ty), d * 0.85, p);
      canvas.drawCircle(Offset(lx, ty + 5), d * 0.85, p);
    }

    cornerDots(inner.left + inset, inner.top + inset);
    cornerDots(inner.right - inset - 5, inner.top + inset);
    cornerDots(inner.left + inset, inner.bottom - inset - 5);
    cornerDots(inner.right - inset - 5, inner.bottom - inset - 5);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final RRect r = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cornerRadius.clamp(0, rect.shortestSide / 2)),
    );

    final RRect inner = r.deflate(_innerInset);
    if (inner.width > 32 && inner.height > 32) {
      final double shortest = math.min(inner.width, inner.height);
      const int targetModules = 23;
      final double module = shortest / targetModules;
      final int cols = math.max(7, (inner.width / module).floor());
      final int rows = math.max(7, (inner.height / module).floor());
      final double offsetX = inner.left + (inner.width - cols * module) / 2;
      final double offsetY = inner.top + (inner.height - rows * module) / 2;
      final double baseDotR = (module * 0.36).clamp(1.0, 2.35);

      canvas.save();
      canvas.clipRRect(inner);

      final Paint wash = Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.radial(
          inner.center,
          shortest * 0.62,
          <Color>[
            color.withValues(alpha: 0.11),
            color.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          <double>[0.0, 0.45, 1.0],
        );
      canvas.drawRRect(inner, wash);

      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          final AttendeeQrDotTier? tier = _moduleTier(row, col, rows, cols);
          if (tier == null) {
            continue;
          }
          final Offset c = Offset(
            offsetX + (col + 0.5) * module,
            offsetY + (row + 0.5) * module,
          );
          if (!inner.contains(c)) {
            continue;
          }

          final double radiusMul;
          final double alpha;
          final Color dotColor;
          switch (tier) {
            case AttendeeQrDotTier.finder:
              radiusMul = 1.28;
              alpha = 0.58;
              dotColor = Color.lerp(color, AppColors.white, 0.42)!;
            case AttendeeQrDotTier.timing:
              radiusMul = 1.08;
              alpha = 0.4;
              dotColor = Color.lerp(color, AppColors.white, 0.22)!;
            case AttendeeQrDotTier.data:
              radiusMul = 1.0;
              alpha = 0.26;
              dotColor = color;
          }

          final double r = baseDotR * radiusMul;
          if (tier == AttendeeQrDotTier.finder) {
            canvas.drawCircle(
              c,
              r * 1.5,
              Paint()
                ..isAntiAlias = true
                ..color = color.withValues(alpha: 0.09),
            );
          }
          final Paint dotPaint = Paint()
            ..isAntiAlias = true
            ..color = dotColor.withValues(alpha: alpha);
          canvas.drawCircle(c, r, dotPaint);
        }
      }

      _paintInnerCornerAccents(
        canvas,
        inner,
        AppColors.white.withValues(alpha: 0.22),
      );
      canvas.restore();
    }

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawRRect(r, strokePaint);
  }

  @override
  bool shouldRepaint(covariant AttendeeQrSquareScanFramePainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      cornerRadius != oldDelegate.cornerRadius;
}

enum AttendeeQrDotTier { finder, timing, data }

/// Custom painter that draws a checkmark path progressively (0..1).
class AttendeeQrCheckmarkPainter extends CustomPainter {
  AttendeeQrCheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 4,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final Path path = Path()
      ..moveTo(w * 0.2, h * 0.5)
      ..lineTo(w * 0.42, h * 0.72)
      ..lineTo(w * 0.82, h * 0.28);

    final List<ui.PathMetric> metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final double totalLength = metrics.fold<double>(
      0,
      (double sum, ui.PathMetric m) => sum + m.length,
    );
    final double drawLength = totalLength * progress.clamp(0, 1);

    double accumulated = 0;
    for (final ui.PathMetric metric in metrics) {
      final double len = metric.length;
      if (accumulated + len <= drawLength) {
        canvas.drawPath(metric.extractPath(0, len), _paint);
        accumulated += len;
      } else {
        final double t = (drawLength - accumulated) / len;
        canvas.drawPath(metric.extractPath(0, len * t), _paint);
        break;
      }
    }
  }

  Paint get _paint => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  bool shouldRepaint(covariant AttendeeQrCheckmarkPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
