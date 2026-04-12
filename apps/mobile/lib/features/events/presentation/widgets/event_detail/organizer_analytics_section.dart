import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_analytics.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/detail_section_header.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_shared/events_shared.dart';

/// Analytics section visible to the event organizer on the detail screen.
///
/// Shows:
/// - Attendance rate ring chart
/// - Joiners over time sparkline
/// - Check-ins by hour bar chart
///
/// Hidden for non-organizers and upcoming events (no data yet).
class OrganizerAnalyticsSection extends StatefulWidget {
  const OrganizerAnalyticsSection({
    super.key,
    required this.event,
  });

  final EcoEvent event;

  @override
  State<OrganizerAnalyticsSection> createState() => _OrganizerAnalyticsSectionState();
}

class _OrganizerAnalyticsSectionState extends State<OrganizerAnalyticsSection> {
  EventAnalytics? _analytics;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    try {
      final EventAnalytics data = await ServiceLocator.instance.eventAnalyticsRepository
          .fetchAnalytics(widget.event.id);
      if (!mounted) return;
      setState(() {
        _analytics = data;
        _loading = false;
        _failed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _analytics = null;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _failed = false;
      _loading = true;
    });
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final EventAnalytics? data = _analytics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DetailSectionHeader(context.l10n.eventsAnalyticsTitle),
        EventsAsyncSection(
          isLoading: _loading,
          hasError: _failed,
          onRetry: _retry,
          retryLabel: context.l10n.eventsAnalyticsRetry,
          errorMessage: context.l10n.eventsAnalyticsLoadFailed,
          skeleton: _buildSkeleton(),
          child: data != null
              ? _buildContent(context, data)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EventAnalytics data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: EventDetailSurfaceDecoration.elevatedCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Top row: attendance ring + stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Semantics(
                label:
                    '${context.l10n.eventsAnalyticsAttendanceRate}, ${data.attendanceRate}%',
                child: _AttendanceRing(
                  rate: data.attendanceRate / 100.0,
                  size: 72,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.eventsAnalyticsAttendanceRate,
                      style: AppTypography.textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${data.attendanceRate}%',
                      style: AppTypography.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: _rateColor(data.attendanceRate),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.checkedInCount} / ${data.totalJoiners} joined',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (data.joinersOverTime.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.eventsAnalyticsJoiners,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              label: context.l10n.eventsAnalyticsJoiners,
              child: SizedBox(
                height: 48,
                child: _Sparkline(
                  data: data.joinersOverTime
                      .map((JoinersOverTimeEntry e) => e.count.toDouble())
                      .toList(),
                  color: AppColors.primary,
                ),
              ),
            ),
          ],

          if (data.checkInsByHour.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.eventsAnalyticsCheckInsByHour,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              label: context.l10n.eventsAnalyticsCheckInsByHour,
              child: SizedBox(
                height: 48,
                child: _BarChart(
                  data: data.checkInsByHour,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _rateColor(int rate) {
    if (rate >= 75) return AppColors.primaryDark;
    if (rate >= 40) return const Color(0xFFF5A623);
    return AppColors.error;
  }
}

// ── Attendance ring ───────────────────────────────────────────────────────────

class _AttendanceRing extends StatelessWidget {
  const _AttendanceRing({required this.rate, required this.size});
  final double rate;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RingPainter(rate: rate),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            '${(rate * 100).round()}%',
            style: AppTypography.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.rate});
  final double rate;

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = 6.0;
    final double radius = (math.min(size.width, size.height) - stroke) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    const double startAngle = -math.pi / 2;

    // Track
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
      // Fill
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi * 2 * rate.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = rate >= 0.75 ? AppColors.primary : const Color(0xFFF5A623)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.rate != rate;
}

// ── Sparkline ─────────────────────────────────────────────────────────────────

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.data, required this.color});
  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _SparklinePainter(data: data, color: color),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.data, required this.color});
  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final double maxVal = data.reduce(math.max);
    if (maxVal == 0) return;

    final double stepX = size.width / (data.length - 1);

    // Area fill
    final Path areaPath = Path();
    areaPath.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = size.height - (data[i] / maxVal) * size.height;
      if (i == 0) {
        areaPath.lineTo(x, y);
      } else {
        areaPath.lineTo(x, y);
      }
    }
    areaPath.lineTo((data.length - 1) * stepX, size.height);
    areaPath.close();
    canvas.drawPath(
      areaPath,
      Paint()..color = color.withValues(alpha: 0.12),
    );

    // Line
    final Path linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = size.height - (data[i] / maxVal) * size.height;
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
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data, required this.color});
  final List<CheckInsByHourEntry> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _BarChartPainter(data: data, color: color),
      size: Size.infinite,
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.data, required this.color});
  final List<CheckInsByHourEntry> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final int maxCount = data.map((CheckInsByHourEntry e) => e.count).reduce(math.max);
    if (maxCount == 0) return;

    final double barWidth = (size.width / data.length) * 0.65;
    final double gap = (size.width / data.length) * 0.35;
    final Paint fill = Paint()..color = color.withValues(alpha: 0.7);
    final Paint bg = Paint()..color = color.withValues(alpha: 0.1);

    for (int i = 0; i < data.length; i++) {
      final double x = i * (barWidth + gap);
      final double barH = (data[i].count / maxCount) * size.height;

      // Background bar
      final RRect bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, size.height),
        const Radius.circular(2),
      );
      canvas.drawRRect(bgRect, bg);

      // Filled bar
      if (barH > 0) {
        final RRect filledRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barH, barWidth, barH),
          const Radius.circular(2),
        );
        canvas.drawRRect(filledRect, fill);
      }
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.data != data;
}
