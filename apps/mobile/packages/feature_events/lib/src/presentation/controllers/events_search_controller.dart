import 'dart:async';

import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:feature_events/src/presentation/controllers/events_feed_controller.dart';
import 'package:feature_events/src/presentation/controllers/events_search_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'events_search_controller.g.dart';

/// Debounced coordinator for ranked `POST /events/search` (via repository refresh).
@Riverpod(keepAlive: true)
class EventsSearchController extends _$EventsSearchController {
  Timer? _debounce;
  bool _alive = true;

  @override
  EventsSearchState build() {
    _alive = true;
    ref.onDispose(() {
      _alive = false;
      cancel();
    });
    return const EventsSearchState();
  }

  EventsSearchRemotePhase get phase => state.phase;
  Object? get lastError => state.lastError;

  void cancel() {
    _debounce?.cancel();
    _debounce = null;
  }

  void clearPhase() {
    if (!_alive) return;
    state = state.copyWith(
      phase: EventsSearchRemotePhase.idle,
      clearLastError: true,
    );
  }

  /// Schedules feed search refresh with merged params after [debounce].
  ///
  /// [mergedBase] must already include chip + sheet merge; [rawText] updates `query`.
  void scheduleTextSearch({
    required String rawText,
    required EcoEventSearchParams mergedBase,
    Duration debounce = const Duration(milliseconds: 400),
  }) {
    _debounce?.cancel();
    _debounce = Timer(debounce, () async {
      if (!_alive) return;
      final String trimmed = rawText.trim();
      final EcoEventSearchParams next = mergedBase.copyWith(
        query: trimmed.isEmpty ? null : trimmed,
        clearQuery: trimmed.isEmpty,
      );

      if (trimmed.isEmpty) {
        state = state.copyWith(
          phase: EventsSearchRemotePhase.idle,
          clearLastError: true,
        );
      } else {
        state = state.copyWith(
          phase: EventsSearchRemotePhase.loading,
          clearLastError: true,
        );
      }

      try {
        final bool ok = await ref
            .read(eventsFeedControllerProvider.notifier)
            .setSearchParams(next);
        final EventsSearchRemotePhase phase = trimmed.isEmpty
            ? EventsSearchRemotePhase.idle
            : (ok
                  ? EventsSearchRemotePhase.ready
                  : EventsSearchRemotePhase.error);
        state = state.copyWith(
          phase: phase,
          lastError: ok ? null : (state.lastError ?? 'refresh_failed'),
          clearLastError: ok,
        );
      } on Object catch (e) {
        if (!_alive) return;
        state = state.copyWith(
          phase: EventsSearchRemotePhase.error,
          lastError: e,
        );
      }
    });
  }
}
