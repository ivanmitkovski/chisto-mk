import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/event_analytics.dart';
import 'package:flutter/material.dart';

class OrganizerAnalyticsAttendanceRing extends StatelessWidget {
  const OrganizerAnalyticsAttendanceRing({
    super.key,
    required this.rate,
    required this.size,
  });

  final double rate;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _OrganizerAnalyticsRingPainter(rate: rate),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            '${(rate * 100).round()}%',
            style: AppTypography.eventsCaptionStrong(
              Theme.of(context).textTheme,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _OrganizerAnalyticsRingPainter extends CustomPainter {
  const _OrganizerAnalyticsRingPainter({required this.rate});
  final double rate;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 6;
    final double radius = (math.min(size.width, size.height) - stroke) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    const double startAngle = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.divider.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (rate > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi * 2 * rate.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = rate >= 0.75 ? AppColors.primary : AppColors.warningAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_OrganizerAnalyticsRingPainter old) => old.rate != rate;
}

class OrganizerAnalyticsJoinCurveChart extends StatelessWidget {
  const OrganizerAnalyticsJoinCurveChart({
    super.key,
    required this.cumulative,
    required this.color,
    required this.reduceMotion,
  });

  final List<int> cumulative;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (cumulative.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _OrganizerAnalyticsJoinCurvePainter(
        data: cumulative.map((int v) => v.toDouble()).toList(growable: false),
        color: color,
        reduceMotion: reduceMotion,
      ),
      size: Size.infinite,
    );
  }
}

class _OrganizerAnalyticsJoinCurvePainter extends CustomPainter {
  const _OrganizerAnalyticsJoinCurvePainter({
    required this.data,
    required this.color,
    required this.reduceMotion,
  });

  final List<double> data;
  final Color color;
  final bool reduceMotion;

  double _yFor(double v, double minV, double maxV, double height) {
    if (maxV <= minV) {
      return height * 0.18;
    }
    final double t = (v - minV) / (maxV - minV);
    return height - t * (height * 0.82) - height * 0.08;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double minV = data.reduce(math.min);
    final double maxV = data.reduce(math.max);

    if (data.length == 1) {
      final double cx = size.width / 2;
      final double cy = _yFor(data[0], minV, maxV, size.height);
      canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = color);
      canvas.drawLine(
        Offset(cx, cy + 4),
        Offset(cx, size.height - 2),
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..strokeWidth = 1,
      );
      return;
    }

    final double stepX = size.width / (data.length - 1);
    final Path areaPath = Path();
    areaPath.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = _yFor(data[i], minV, maxV, size.height);
      areaPath.lineTo(x, y);
    }
    areaPath.lineTo((data.length - 1) * stepX, size.height);
    areaPath.close();

    final Paint fillPaint = reduceMotion
        ? (Paint()..color = color.withValues(alpha: 0.12))
        : (Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.06),
              ],
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(areaPath, fillPaint);

    final Path linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = _yFor(data[i], minV, maxV, size.height);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_OrganizerAnalyticsJoinCurvePainter old) =>
      old.data != data ||
      old.color != color ||
      old.reduceMotion != reduceMotion;
}

class OrganizerAnalyticsCheckInsBarChart extends StatelessWidget {
  const OrganizerAnalyticsCheckInsBarChart({
    super.key,
    required this.data,
    required this.color,
    required this.peakHour,
  });

  final List<CheckInsByHourEntry> data;
  final Color color;
  final int peakHour;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OrganizerAnalyticsBarChartPainter(
        data: data,
        color: color,
        peakHour: peakHour,
      ),
      size: Size.infinite,
    );
  }
}

class _OrganizerAnalyticsBarChartPainter extends CustomPainter {
  const _OrganizerAnalyticsBarChartPainter({
    required this.data,
    required this.color,
    required this.peakHour,
  });

  final List<CheckInsByHourEntry> data;
  final Color color;
  final int peakHour;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final int maxCount = data
        .map((CheckInsByHourEntry e) => e.count)
        .reduce(math.max);
    final int n = data.length;
    final double slotW = size.width / n;
    final double barWidth = slotW * 0.62;
    final double inset = (slotW - barWidth) / 2;
    final Paint bg = Paint()..color = color.withValues(alpha: 0.08);
    final Paint fill = Paint()..color = color.withValues(alpha: 0.72);
    final Paint peakFill = Paint()..color = color.withValues(alpha: 0.95);

    for (int i = 0; i < n; i++) {
      final double x = i * slotW + inset;
      final RRect bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, size.height),
        const Radius.circular(2),
      );
      canvas.drawRRect(bgRect, bg);

      final int count = data[i].count;
      final double norm = maxCount > 0 ? count / maxCount : 0;
      final double barH = norm * size.height;
      if (barH > 0) {
        final Paint p =
            data[i].hour == peakHour && count == maxCount && maxCount > 0
            ? peakFill
            : fill;
        final RRect filledRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barH, barWidth, barH),
          const Radius.circular(2),
        );
        canvas.drawRRect(filledRect, p);
      }
    }

    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()..color = AppColors.divider.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_OrganizerAnalyticsBarChartPainter old) =>
      old.data != data || old.color != color || old.peakHour != peakHour;
}

Color organizerAnalyticsRateColor(int rate) {
  if (rate >= 75) return AppColors.primaryDark;
  if (rate >= 40) return AppColors.warningAccent;
  return AppColors.error;
}

int organizerAnalyticsPeakHour(List<CheckInsByHourEntry> hours) {
  int bestH = 0;
  int bestC = -1;
  for (final CheckInsByHourEntry e in hours) {
    if (e.count > bestC) {
      bestC = e.count;
      bestH = e.hour;
    }
  }
  return bestH;
}
