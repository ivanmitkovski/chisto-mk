import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/events/presentation/view_models/organizer_analytics_view_model.dart';
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
/// Shows attendance, cumulative join curve, and 24h UTC check-in distribution.
class OrganizerAnalyticsSection extends StatefulWidget {
  const OrganizerAnalyticsSection({
    super.key,
    required this.event,
    this.fetchAnalytics,
  });

  final EcoEvent event;

  /// When set (e.g. tests), replaces the default API repository fetch.
  final Future<EventAnalytics> Function(String eventId)? fetchAnalytics;

  @override
  State<OrganizerAnalyticsSection> createState() => _OrganizerAnalyticsSectionState();
}

class _OrganizerAnalyticsSectionState extends State<OrganizerAnalyticsSection> {
  late final OrganizerAnalyticsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = OrganizerAnalyticsViewModel(
      eventId: widget.event.id,
      fetchAnalytics: widget.fetchAnalytics != null
          ? widget.fetchAnalytics!
          : ServiceLocator.instance.eventAnalyticsRepository.fetchAnalytics,
    );
    _vm.addListener(_onVm);
    unawaited(_vm.fetch(silent: false));
  }

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    _vm.dispose();
    super.dispose();
  }

  void _onVm() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _retry() async {
    await _vm.fetch(silent: false);
  }

  @override
  Widget build(BuildContext context) {
    final EventAnalytics? data = _vm.analytics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DetailSectionHeader(context.l10n.eventsAnalyticsTitle),
        EventsAsyncSection(
          isLoading: _vm.loading,
          hasError: _vm.failed,
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
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final int peakHour = _peakHour(data.checkInsByHour);
    final int peakCount = data.checkInsByHour.isEmpty ? 0 : data.checkInsByHour[peakHour].count;
    final String peakLabel = '${peakHour.toString().padLeft(2, '0')}:00';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: EventDetailSurfaceDecoration.detailModule(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Row(
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
                            style: AppTypography.eventsSheetDateTileLabel(
                              Theme.of(context).textTheme,
                            ),
                          ),
                          Text(
                            '${data.attendanceRate}%',
                            style: AppTypography.eventsAnalyticsHeroMetric(
                              Theme.of(context).textTheme,
                              color: _rateColor(data.attendanceRate),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.eventsAnalyticsCheckedInRatio(
                              data.checkedInCount,
                              data.totalJoiners,
                            ),
                            style: AppTypography.eventsListCardMeta(
                              Theme.of(context).textTheme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.fetchAnalytics == null)
                IconButton(
                  tooltip: context.l10n.eventsAnalyticsRefresh,
                  onPressed: (_vm.loading || _vm.silentRefresh)
                      ? null
                      : () => unawaited(_vm.fetch(silent: true)),
                  icon: _vm.silentRefresh
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh, color: AppColors.textMuted),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.eventsAnalyticsJoiners,
            style: AppTypography.eventsMicroSectionHeading(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (data.joinersCumulative.isEmpty)
            _emptyCaption(context, context.l10n.eventsAnalyticsJoinersEmpty)
          else
            Semantics(
              label: context.l10n.eventsAnalyticsSemanticsJoinCurve(
                data.joinersCumulative.first.cumulativeJoiners,
                data.joinersCumulative.last.cumulativeJoiners,
                data.joinersCumulative.length,
              ),
              child: SizedBox(
                height: 52,
                child: _JoinCurveChart(
                  cumulative: data.joinersCumulative.map((JoinersCumulativeEntry e) => e.cumulativeJoiners).toList(),
                  color: AppColors.primary,
                  reduceMotion: reduceMotion,
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.eventsAnalyticsCheckInsByHour,
            style: AppTypography.eventsMicroSectionHeading(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (data.checkInsByHour.every((CheckInsByHourEntry e) => e.count == 0))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _emptyCaption(context, context.l10n.eventsAnalyticsCheckInsEmpty),
            ),
          Semantics(
            label: peakCount > 0
                ? context.l10n.eventsAnalyticsSemanticsCheckInHeatmap(peakCount, peakLabel)
                : context.l10n.eventsAnalyticsSemanticsCheckInNoData,
            child: SizedBox(
              height: 56,
              child: _BarChart(
                data: data.checkInsByHour,
                color: AppColors.primary,
                peakHour: peakHour,
              ),
            ),
          ),
          if (peakCount > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.eventsAnalyticsPeakCheckInsUtc(peakLabel),
              style: AppTypography.eventsListCardMeta(
                Theme.of(context).textTheme,
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _peakHour(List<CheckInsByHourEntry> hours) {
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

  Widget _emptyCaption(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.eventsListCardMeta(Theme.of(context).textTheme),
      ),
    );
  }

  Color _rateColor(int rate) {
    if (rate >= 75) return AppColors.primaryDark;
    if (rate >= 40) return AppColors.warningAccent;
    return AppColors.error;
  }
}

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
            style: AppTypography.eventsCaptionStrong(
              Theme.of(context).textTheme,
            ).copyWith(fontWeight: FontWeight.w700),
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
  bool shouldRepaint(_RingPainter old) => old.rate != rate;
}

class _JoinCurveChart extends StatelessWidget {
  const _JoinCurveChart({
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
      painter: _JoinCurvePainter(
        data: cumulative.map((int v) => v.toDouble()).toList(growable: false),
        color: color,
        reduceMotion: reduceMotion,
      ),
      size: Size.infinite,
    );
  }
}

class _JoinCurvePainter extends CustomPainter {
  const _JoinCurvePainter({
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
      canvas.drawCircle(
        Offset(cx, cy),
        4,
        Paint()..color = color,
      );
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
      if (i == 0) {
        areaPath.lineTo(x, y);
      } else {
        areaPath.lineTo(x, y);
      }
    }
    areaPath.lineTo((data.length - 1) * stepX, size.height);
    areaPath.close();

    final Paint fillPaint = reduceMotion
        ? (Paint()..color = color.withValues(alpha: 0.12))
        : (Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[color.withValues(alpha: 0.22), color.withValues(alpha: 0.06)],
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
  bool shouldRepaint(_JoinCurvePainter old) =>
      old.data != data || old.color != color || old.reduceMotion != reduceMotion;
}

class _BarChart extends StatelessWidget {
  const _BarChart({
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
      painter: _BarChartPainter(data: data, color: color, peakHour: peakHour),
      size: Size.infinite,
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
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

    final int maxCount = data.map((CheckInsByHourEntry e) => e.count).reduce(math.max);
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
        final Paint p = data[i].hour == peakHour && count == maxCount && maxCount > 0 ? peakFill : fill;
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
  bool shouldRepaint(_BarChartPainter old) =>
      old.data != data || old.color != color || old.peakHour != peakHour;
}
