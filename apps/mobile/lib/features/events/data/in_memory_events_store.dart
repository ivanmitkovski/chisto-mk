import 'dart:async';
import 'dart:collection';

import 'package:chisto_mobile/features/events/data/events_local_cache.dart';
import 'package:chisto_mobile/features/events/data/mock_eco_events.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:flutter/foundation.dart';

class InMemoryEventsStore extends ChangeNotifier implements EventsRepository {
  InMemoryEventsStore._();

  static final InMemoryEventsStore instance = InMemoryEventsStore._();

  final EventsLocalCache _localCache = const EventsLocalCache();
  List<EcoEvent> _events = <EcoEvent>[];
  Completer<void>? _hydrationCompleter;
  bool _didStartLoad = false;

  @override
  bool get isReady => _hydrationCompleter?.isCompleted ?? false;

  @override
  Future<void> get ready =>
      _hydrationCompleter?.future ?? Future<void>.value();

  @override
  List<EcoEvent> get events => List<EcoEvent>.unmodifiable(_events);

  @override
  void loadInitialIfNeeded() {
    if (_didStartLoad) {
      return;
    }
    _didStartLoad = true;
    _hydrationCompleter = Completer<void>();
    _events = buildMockEcoEventsSeed();
    notifyListeners();
    unawaited(_hydrateFromCache());
  }

  @override
  void resetToSeed() {
    _events = buildMockEcoEventsSeed();
    notifyListeners();
    _persistSnapshot();
  }

  @override
  EcoEvent? findById(String id) {
    for (final EcoEvent event in _events) {
      if (event.id == id) {
        return event;
      }
    }
    return null;
  }

  @override
  EcoEvent? findBySiteAndTitle({
    required String siteId,
    required String title,
  }) {
    final String normalizedTitle = title.trim().toLowerCase();
    for (final EcoEvent event in _events) {
      if (event.siteId == siteId &&
          event.title.trim().toLowerCase() == normalizedTitle) {
        return event;
      }
    }
    return null;
  }

  @override
  void create(EcoEvent event) {
    _events = <EcoEvent>[event, ..._events];
    notifyListeners();
    _persistSnapshot();
  }

  @override
  bool updateStatus(String id, EcoEventStatus status) {
    bool changed = false;
    _events = _events.map((EcoEvent event) {
      if (event.id != id) {
        return event;
      }
      if (!event.canTransitionTo(status)) {
        return event;
      }

      changed = true;
      if (status == EcoEventStatus.inProgress) {
        final String sessionId =
            event.activeCheckInSessionId ??
            'sess_${DateTime.now().millisecondsSinceEpoch}_${event.id}';
        return event.copyWith(
          status: status,
          activeCheckInSessionId: sessionId,
          isCheckInOpen: true,
        );
      }

      return event.copyWith(
        status: status,
        isCheckInOpen: false,
        clearActiveCheckInSessionId: true,
      );
    }).toList(growable: false);

    if (changed) {
      notifyListeners();
      _persistSnapshot();
    }
    return changed;
  }

  @override
  bool toggleJoin(String id) {
    bool changed = false;
    _events = _events.map((EcoEvent event) {
      if (event.id != id || !event.isJoinable) {
        return event;
      }
      if (!event.isJoined && event.maxParticipants != null && event.participantCount >= event.maxParticipants!) {
        return event;
      }
      changed = true;
      final bool nextJoined = !event.isJoined;
      final int nextCount = nextJoined
          ? event.participantCount + 1
          : (event.participantCount - 1).clamp(0, 1000000);
      return event.copyWith(
        isJoined: nextJoined,
        participantCount: nextCount,
      );
    }).toList(growable: false);

    if (changed) {
      notifyListeners();
      _persistSnapshot();
    }
    return changed;
  }

  @override
  bool setCheckInOpen({
    required String eventId,
    required bool isOpen,
  }) {
    bool changed = false;
    _events = _events.map((EcoEvent event) {
      if (event.id != eventId || event.status != EcoEventStatus.inProgress) {
        return event;
      }
      if (event.isCheckInOpen == isOpen) {
        return event;
      }
      changed = true;
      return event.copyWith(isCheckInOpen: isOpen);
    }).toList(growable: false);
    if (changed) {
      notifyListeners();
      _persistSnapshot();
    }
    return changed;
  }

  @override
  bool rotateCheckInSession({
    required String eventId,
    required String sessionId,
  }) {
    bool changed = false;
    _events = _events.map((EcoEvent event) {
      if (event.id != eventId || event.status != EcoEventStatus.inProgress) {
        return event;
      }
      if (event.activeCheckInSessionId == sessionId) {
        return event;
      }
      changed = true;
      return event.copyWith(activeCheckInSessionId: sessionId);
    }).toList(growable: false);
    if (changed) {
      notifyListeners();
      _persistSnapshot();
    }
    return changed;
  }

  @override
  bool setCheckedInCount({
    required String eventId,
    required int checkedInCount,
  }) {
    bool changed = false;
    _events = _events.map((EcoEvent event) {
      if (event.id != eventId) {
        return event;
      }
      final int safeCount = checkedInCount.clamp(0, event.participantCount);
      if (event.checkedInCount == safeCount) {
        return event;
      }
      changed = true;
      return event.copyWith(checkedInCount: safeCount);
    }).toList(growable: false);

    if (changed) {
      notifyListeners();
      _persistSnapshot();
    }
    return changed;
  }

  @override
  bool setAttendeeCheckInStatus({
    required String eventId,
    required AttendeeCheckInStatus status,
    DateTime? checkedInAt,
  }) {
    bool changed = false;
    _events = _events.map((EcoEvent event) {
      if (event.id != eventId) {
        return event;
      }
      if (event.attendeeCheckInStatus == status &&
          event.attendeeCheckedInAt == checkedInAt) {
        return event;
      }
      changed = true;
      return event.copyWith(
        attendeeCheckInStatus: status,
        attendeeCheckedInAt: checkedInAt,
        clearAttendeeCheckedInAt:
            status == AttendeeCheckInStatus.notCheckedIn && checkedInAt == null,
      );
    }).toList(growable: false);

    if (changed) {
      notifyListeners();
      _persistSnapshot();
    }
    return changed;
  }

  @override
  bool setReminder({
    required String eventId,
    required bool enabled,
    DateTime? reminderAt,
  }) {
    bool changed = false;
    _events = _events.map((EcoEvent event) {
      if (event.id != eventId) {
        return event;
      }
      if (event.reminderEnabled == enabled && event.reminderAt == reminderAt) {
        return event;
      }
      changed = true;
      return event.copyWith(
        reminderEnabled: enabled,
        reminderAt: reminderAt,
        clearReminderAt: !enabled || reminderAt == null,
      );
    }).toList(growable: false);
    if (changed) {
      notifyListeners();
      _persistSnapshot();
    }
    return changed;
  }

  @override
  bool setAfterImages({
    required String eventId,
    required List<String> imagePaths,
  }) {
    bool changed = false;
    final List<String> normalized = LinkedHashSet<String>.from(imagePaths).toList(growable: false);
    _events = _events.map((EcoEvent event) {
      if (event.id != eventId) {
        return event;
      }
      if (listEquals(event.afterImagePaths, normalized)) {
        return event;
      }
      changed = true;
      return event.copyWith(afterImagePaths: normalized);
    }).toList(growable: false);

    if (changed) {
      notifyListeners();
      _persistSnapshot();
    }
    return changed;
  }

  Future<void> _hydrateFromCache() async {
    try {
      final List<EcoEvent>? cached = await _localCache.readEvents();
      if (cached != null && cached.isNotEmpty) {
        _events = cached;
        notifyListeners();
      } else {
        _persistSnapshot();
      }
    } finally {
      _hydrationCompleter?.complete();
    }
  }

  void _persistSnapshot() {
    unawaited(_localCache.writeEvents(_events));
  }
}
