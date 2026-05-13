import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';

/// Remote text search phases for the events discovery feed (debounced list refresh).
enum EventsSearchRemotePhase {
  idle,
  loading,
  ready,
  error,
}

typedef EventsSearchParamsRunner = Future<bool> Function(EcoEventSearchParams next);

/// Debounced coordinator for ranked `POST /events/search` (via repository refresh).
class EventsSearchController extends ChangeNotifier {
  EventsSearchController({required EventsSearchParamsRunner runSearchParams})
      : _runSearchParams = runSearchParams;

  final EventsSearchParamsRunner _runSearchParams;
  Timer? _debounce;

  EventsSearchRemotePhase _phase = EventsSearchRemotePhase.idle;
  Object? _lastError;

  EventsSearchRemotePhase get phase => _phase;

  Object? get lastError => _lastError;

  void cancel() {
    _debounce?.cancel();
    _debounce = null;
  }

  void clearPhase() {
    _phase = EventsSearchRemotePhase.idle;
    _lastError = null;
    notifyListeners();
  }

  /// Schedules [runSearchParams] with merged params after [debounce].
  ///
  /// [mergedBase] must already include chip + sheet merge; [rawText] updates `query`.
  void scheduleTextSearch({
    required String rawText,
    required EcoEventSearchParams mergedBase,
    Duration debounce = const Duration(milliseconds: 400),
  }) {
    _debounce?.cancel();
    _debounce = Timer(debounce, () async {
      final String trimmed = rawText.trim();
      final EcoEventSearchParams next = mergedBase.copyWith(
        query: trimmed.isEmpty ? null : trimmed,
        clearQuery: trimmed.isEmpty,
      );

      if (trimmed.isEmpty) {
        _phase = EventsSearchRemotePhase.idle;
        _lastError = null;
        notifyListeners();
      } else {
        _phase = EventsSearchRemotePhase.loading;
        _lastError = null;
        notifyListeners();
      }

      try {
        final bool ok = await _runSearchParams(next);
        _phase = trimmed.isEmpty
            ? EventsSearchRemotePhase.idle
            : (ok ? EventsSearchRemotePhase.ready : EventsSearchRemotePhase.error);
        if (!ok) {
          _lastError ??= 'refresh_failed';
        }
      } on Object catch (e) {
        _phase = EventsSearchRemotePhase.error;
        _lastError = e;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}
