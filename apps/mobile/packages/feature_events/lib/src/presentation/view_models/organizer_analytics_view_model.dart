import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:feature_events/src/domain/models/event_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'organizer_analytics_view_model.g.dart';

class OrganizerAnalyticsState {
  const OrganizerAnalyticsState({
    this.analytics,
    this.loading = true,
    this.silentRefresh = false,
    this.failed = false,
    this.lastFetchedAt,
  });

  final EventAnalytics? analytics;
  final bool loading;
  final bool silentRefresh;
  final bool failed;
  final DateTime? lastFetchedAt;

  OrganizerAnalyticsState copyWith({
    EventAnalytics? analytics,
    bool clearAnalytics = false,
    bool? loading,
    bool? silentRefresh,
    bool? failed,
    DateTime? lastFetchedAt,
    bool clearLastFetchedAt = false,
  }) {
    return OrganizerAnalyticsState(
      analytics: clearAnalytics ? null : (analytics ?? this.analytics),
      loading: loading ?? this.loading,
      silentRefresh: silentRefresh ?? this.silentRefresh,
      failed: failed ?? this.failed,
      lastFetchedAt: clearLastFetchedAt
          ? null
          : (lastFetchedAt ?? this.lastFetchedAt),
    );
  }
}

/// Loads organizer-only analytics for [OrganizerAnalyticsSection].
@riverpod
class OrganizerAnalyticsViewModel extends _$OrganizerAnalyticsViewModel {
  Future<EventAnalytics> Function(String eventId)? _fetchOverride;
  bool _disposed = false;

  @override
  OrganizerAnalyticsState build(String eventId) {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });
    return const OrganizerAnalyticsState();
  }

  // ignore: use_setters_to_change_properties, dependency-injection/test override hook, not a public property
  void setFetchOverride(
    Future<EventAnalytics> Function(String eventId)? fetchAnalytics,
  ) {
    _fetchOverride = fetchAnalytics;
  }

  Future<EventAnalytics> _fetch(String eventId) {
    final Future<EventAnalytics> Function(String eventId) fetch =
        _fetchOverride ??
        ref.read(eventAnalyticsRepositoryProvider).fetchAnalytics;
    return fetch(eventId);
  }

  Future<void> fetch({required bool silent}) async {
    if (!silent) {
      state = state.copyWith(loading: true, failed: false);
    } else {
      state = state.copyWith(silentRefresh: true);
    }
    try {
      final EventAnalytics data = await _fetch(eventId);
      if (_disposed) return;
      state = state.copyWith(
        analytics: data,
        lastFetchedAt: DateTime.now().toUtc(),
        loading: false,
        silentRefresh: false,
        failed: false,
      );
    } on Object {
      if (_disposed) return;
      state = state.copyWith(
        loading: false,
        silentRefresh: false,
        failed: !silent || state.failed,
        clearAnalytics: !silent,
      );
    }
  }
}
