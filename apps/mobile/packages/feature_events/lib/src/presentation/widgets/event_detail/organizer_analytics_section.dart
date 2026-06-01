import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/event_analytics.dart';
import 'package:feature_events/src/presentation/utils/organizer_analytics_formatting.dart';
import 'package:feature_events/src/presentation/view_models/organizer_analytics_view_model.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/detail_section_header.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/impact_summary_section.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/organizer_analytics_charts.dart';
import 'package:feature_events/src/presentation/widgets/events_shared/events_shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Organizer-only analytics on event detail: frameless, full-width within body gutter.
class OrganizerAnalyticsSection extends ConsumerStatefulWidget {
  const OrganizerAnalyticsSection({
    super.key,
    required this.event,
    this.fetchAnalytics,
  });

  final EcoEvent event;

  /// When set (e.g. tests), replaces the default API repository fetch.
  final Future<EventAnalytics> Function(String eventId)? fetchAnalytics;

  @override
  ConsumerState<OrganizerAnalyticsSection> createState() =>
      _OrganizerAnalyticsSectionState();
}

class _OrganizerAnalyticsSectionState
    extends ConsumerState<OrganizerAnalyticsSection> {
  static const Duration _livePollInterval = Duration(seconds: 15);

  Timer? _livePollTimer;

  OrganizerAnalyticsViewModelProvider get _vmProvider =>
      organizerAnalyticsViewModelProvider(widget.event.id);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _configureAndFetch(initial: true);
    });
    _syncLivePollTimer();
  }

  @override
  void didUpdateWidget(covariant OrganizerAnalyticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id) {
      _livePollTimer?.cancel();
      _configureAndFetch(initial: true);
      _syncLivePollTimer();
    } else if (oldWidget.event.participantCount !=
            widget.event.participantCount ||
        oldWidget.event.checkedInCount != widget.event.checkedInCount) {
      unawaited(ref.read(_vmProvider.notifier).fetch(silent: true));
    }
    if (oldWidget.event.status != widget.event.status) {
      _syncLivePollTimer();
    }
    if (oldWidget.fetchAnalytics != widget.fetchAnalytics) {
      _configureFetchOverride();
    }
  }

  @override
  void dispose() {
    _livePollTimer?.cancel();
    super.dispose();
  }

  void _configureFetchOverride() {
    ref.read(_vmProvider.notifier).setFetchOverride(widget.fetchAnalytics);
  }

  void _configureAndFetch({required bool initial}) {
    _configureFetchOverride();
    unawaited(ref.read(_vmProvider.notifier).fetch(silent: !initial));
  }

  void _syncLivePollTimer() {
    _livePollTimer?.cancel();
    _livePollTimer = null;
    if (widget.fetchAnalytics != null) {
      return;
    }
    if (widget.event.status != EcoEventStatus.inProgress) {
      return;
    }
    _livePollTimer = Timer.periodic(_livePollInterval, (_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(_vmProvider.notifier).fetch(silent: true));
    });
  }

  Future<void> _retry() async {
    await ref.read(_vmProvider.notifier).fetch(silent: false);
  }

  bool get _isLive => widget.event.status == EcoEventStatus.inProgress;

  _AnalyticsHeadline _headlineFor(EventAnalytics? data) {
    if (data != null) {
      final int totalCheckIns = data.checkInsByHour.fold<int>(
        0,
        (int s, CheckInsByHourEntry e) => s + e.count,
      );
      return _AnalyticsHeadline(
        totalJoiners: data.totalJoiners,
        checkedInCount: data.checkedInCount,
        attendanceRate: data.attendanceRate,
        totalCheckIns: totalCheckIns,
        lastJoinAt: data.lastJoinAt,
        lastCheckInAt: data.lastCheckInAt,
      );
    }
    return _AnalyticsHeadline(
      totalJoiners: widget.event.participantCount,
      checkedInCount: widget.event.checkedInCount,
      attendanceRate: widget.event.participantCount > 0
          ? ((widget.event.checkedInCount / widget.event.participantCount) *
                    100)
                .round()
          : 0,
      totalCheckIns: null,
      lastJoinAt: null,
      lastCheckInAt: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final OrganizerAnalyticsState vm = ref.watch(_vmProvider);
    final EventAnalytics? data = vm.analytics;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime now = DateTime.now().toUtc();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DetailSectionHeader(
          context.l10n.eventsAnalyticsTitle,
          trailing: _buildHeaderTrailing(context),
        ),
        if (vm.lastFetchedAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              context.l10n.eventsAnalyticsUpdatedAgo(
                formatAnalyticsRelativeTime(
                  context.l10n,
                  vm.lastFetchedAt!,
                  now,
                ),
              ),
              style: AppTypography.eventsListCardMeta(textTheme),
            ),
          ),
        EventsAsyncSection(
          isLoading: vm.loading,
          hasError: vm.failed,
          onRetry: _retry,
          retryLabel: context.l10n.eventsAnalyticsRetry,
          errorMessage: context.l10n.eventsAnalyticsLoadFailed,
          horizontalPadding: 0,
          skeleton: _buildSkeleton(),
          child: data != null || (!vm.loading && !vm.failed)
              ? _buildContent(context, data, _headlineFor(data))
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildHeaderTrailing(BuildContext context) {
    final OrganizerAnalyticsState vm = ref.watch(_vmProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_isLive) ...<Widget>[
          ImpactBadge(label: context.l10n.eventsAnalyticsLive),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (widget.fetchAnalytics == null)
          Semantics(
            button: true,
            label: context.l10n.eventsAnalyticsRefresh,
            child: SizedBox(
              width: 44,
              height: 44,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: (vm.loading || vm.silentRefresh)
                    ? null
                    : () => unawaited(
                        ref.read(_vmProvider.notifier).fetch(silent: true),
                      ),
                child: vm.silentRefresh
                    ? const Center(
                        child: AppLoadingIndicator(
                          size: AppLoadingIndicatorSize.sm,
                        ),
                      )
                    : const Icon(
                        CupertinoIcons.arrow_clockwise,
                        size: 22,
                        color: AppColors.textMuted,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EventAnalytics? data,
    _AnalyticsHeadline headline,
  ) {
    if (data == null) {
      return _buildHeroBand(context, headline, showCharts: false);
    }

    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final int peakHour = organizerAnalyticsPeakHour(data.checkInsByHour);
    final int peakCount = data.checkInsByHour.isEmpty
        ? 0
        : data.checkInsByHour[peakHour].count;
    final String peakLabel = '${peakHour.toString().padLeft(2, '0')}:00';
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime now = DateTime.now().toUtc();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeroBand(context, headline, showCharts: false),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.eventsAnalyticsJoiners,
          style: AppTypography.eventsMicroSectionHeading(textTheme),
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
            child: _chartBand(
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: OrganizerAnalyticsJoinCurveChart(
                  cumulative: data.joinersCumulative
                      .map((JoinersCumulativeEntry e) => e.cumulativeJoiners)
                      .toList(),
                  color: AppColors.primary,
                  reduceMotion: reduceMotion,
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.eventsAnalyticsCheckInsByHour,
          style: AppTypography.eventsMicroSectionHeading(textTheme),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (data.checkInsByHour.every((CheckInsByHourEntry e) => e.count == 0))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _emptyCaption(
              context,
              context.l10n.eventsAnalyticsCheckInsEmpty,
            ),
          ),
        Semantics(
          label: peakCount > 0
              ? context.l10n.eventsAnalyticsSemanticsCheckInHeatmap(
                  peakCount,
                  peakLabel,
                )
              : context.l10n.eventsAnalyticsSemanticsCheckInNoData,
          child: _chartBand(
            child: SizedBox(
              width: double.infinity,
              height: 72,
              child: OrganizerAnalyticsCheckInsBarChart(
                data: data.checkInsByHour,
                color: AppColors.primary,
                peakHour: peakHour,
              ),
            ),
          ),
        ),
        if (headline.totalCheckIns != null &&
            headline.totalCheckIns! > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.eventsAnalyticsTotalCheckInsSummary(
              headline.totalCheckIns!,
            ),
            style: AppTypography.eventsListCardMeta(textTheme),
          ),
        ],
        if (peakCount > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.eventsAnalyticsPeakCheckInsUtc(peakLabel),
            style: AppTypography.eventsListCardMeta(textTheme),
          ),
        ],
        if (headline.lastJoinAt != null ||
            headline.lastCheckInAt != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          if (headline.lastJoinAt != null)
            Text(
              context.l10n.eventsAnalyticsLastJoin(
                formatAnalyticsRelativeTime(
                  context.l10n,
                  headline.lastJoinAt!,
                  now,
                ),
              ),
              style: AppTypography.eventsListCardMeta(textTheme),
            ),
          if (headline.lastCheckInAt != null)
            Text(
              context.l10n.eventsAnalyticsLastCheckIn(
                formatAnalyticsRelativeTime(
                  context.l10n,
                  headline.lastCheckInAt!,
                  now,
                ),
              ),
              style: AppTypography.eventsListCardMeta(textTheme),
            ),
        ],
      ],
    );
  }

  Widget _buildHeroBand(
    BuildContext context,
    _AnalyticsHeadline headline, {
    required bool showCharts,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int pending = (headline.totalJoiners - headline.checkedInCount).clamp(
      0,
      headline.totalJoiners,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              label:
                  '${context.l10n.eventsAnalyticsAttendanceRate}, ${headline.attendanceRate}%',
              child: OrganizerAnalyticsAttendanceRing(
                rate: headline.attendanceRate / 100.0,
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
                    style: AppTypography.eventsSheetDateTileLabel(textTheme),
                  ),
                  Text(
                    '${headline.attendanceRate}%',
                    style: AppTypography.eventsAnalyticsHeroMetric(
                      textTheme,
                      color: organizerAnalyticsRateColor(
                        headline.attendanceRate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.eventsAnalyticsCheckedInRatio(
                      headline.checkedInCount,
                      headline.totalJoiners,
                    ),
                    style: AppTypography.eventsListCardMeta(textTheme),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            ImpactBadge(
              label: context.l10n.eventsAnalyticsStatJoined(
                headline.totalJoiners,
              ),
            ),
            ImpactBadge(
              label: context.l10n.eventsAnalyticsStatCheckedIn(
                headline.checkedInCount,
              ),
            ),
            ImpactBadge(
              label: context.l10n.eventsAnalyticsStatPending(pending),
            ),
            if (headline.totalCheckIns != null)
              ImpactBadge(
                label: context.l10n.eventsAnalyticsStatTotalCheckIns(
                  headline.totalCheckIns!,
                ),
              ),
          ],
        ),
        if (showCharts) const SizedBox.shrink(),
      ],
    );
  }

  Widget _chartBand({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.detailSurfaceGrouped,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: child,
      ),
    );
  }

  Widget _emptyCaption(BuildContext context, String text) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.eventsListCardMeta(Theme.of(context).textTheme),
      ),
    );
  }
}

class _AnalyticsHeadline {
  const _AnalyticsHeadline({
    required this.totalJoiners,
    required this.checkedInCount,
    required this.attendanceRate,
    required this.lastJoinAt,
    required this.lastCheckInAt,
    this.totalCheckIns,
  });

  final int totalJoiners;
  final int checkedInCount;
  final int attendanceRate;
  final int? totalCheckIns;
  final DateTime? lastJoinAt;
  final DateTime? lastCheckInAt;
}
