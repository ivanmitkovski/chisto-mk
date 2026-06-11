import 'dart:async';

import 'package:feature_events/src/domain/models/eco_event_filter.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:feature_events/src/domain/models/events_list_page_snapshot.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/utils/events_feed_search_merge.dart';
import 'package:flutter/foundation.dart';

/// Debounced filter preview for [EventsFilterSheet] footer CTA.
class EventsFilterPreviewController extends ChangeNotifier {
  EventsFilterPreviewController({
    required EventsRepository repository,
    required EcoEventFilter activeChip,
    required EcoEventSearchParams initialDraft,
    Duration debounce = const Duration(milliseconds: 400),
  }) : _repository = repository,
       _activeChip = activeChip,
       _draft = initialDraft,
       _debounce = debounce {
    schedulePreview();
  }

  final EventsRepository _repository;
  final EcoEventFilter _activeChip;
  final Duration _debounce;

  EcoEventSearchParams _draft;
  Timer? _debounceTimer;
  int _requestGeneration = 0;

  bool _loading = false;
  EventsListPageSnapshot? _snapshot;
  Object? _error;
  EcoEventSearchParams? _cachedDraft;
  EcoEventFilter? _cachedChip;
  EventsListPageSnapshot? _cachedSnapshot;

  bool get isLoading => _loading;
  EventsListPageSnapshot? get snapshot => _snapshot;
  Object? get error => _error;

  EcoEventSearchParams get draft => _draft;

  void updateDraft(EcoEventSearchParams draft) {
    _draft = draft;
    schedulePreview();
    notifyListeners();
  }

  void schedulePreview() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      unawaited(_runPreview());
    });
  }

  Future<void> _runPreview() async {
    final EcoEventSearchParams merged = EventsFeedSearchMerge.mergedForChip(
      _draft,
      _activeChip,
    );
    if (_cachedDraft == merged &&
        _cachedChip == _activeChip &&
        _cachedSnapshot != null) {
      _snapshot = _cachedSnapshot;
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }

    final int generation = ++_requestGeneration;
    _loading = _snapshot == null;
    _error = null;
    notifyListeners();

    try {
      final EventsListPageSnapshot result = await _repository
          .fetchEventsFilterPreview(merged);
      if (generation != _requestGeneration) {
        return;
      }
      _snapshot = result;
      _cachedDraft = merged;
      _cachedChip = _activeChip;
      _cachedSnapshot = result;
      _error = null;
    } on Object catch (error) {
      if (generation != _requestGeneration) {
        return;
      }
      _error = error;
    } finally {
      if (generation == _requestGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
