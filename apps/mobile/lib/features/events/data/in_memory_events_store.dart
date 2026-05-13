import 'dart:async';
import 'dart:collection';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/events/data/events_local_cache.dart';
import 'package:chisto_mobile/features/events/data/mock_eco_events.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_join_toggle_result.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/models/event_schedule_conflict_preview.dart';
import 'package:chisto_mobile/features/events/domain/models/event_update_payload.dart';
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
  List<String> get lastRankedSearchSuggestions => const <String>[];

  @override
  DateTime? get lastSuccessfulListRefreshAt => null;

  @override
  bool get hasMoreEvents => false;

  @override
  bool get lastGlobalListLoadFailed => false;

  @override
  bool get isShowingStaleCachedEvents => false;

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
  Future<void> refreshEvents({EcoEventSearchParams? params}) async {}

  /// When true (tests only), [prefetchEvent] with `force: true` returns false so
  /// detail screens can exercise stale-cache banners while the event remains in memory.
  bool simulateDetailPrefetchFailureOnForce = false;

  @override
  Future<bool> prefetchEvent(String id, {bool force = false}) async {
    if (simulateDetailPrefetchFailureOnForce && force) {
      return false;
    }
    return findById(id) != null;
  }

  @override
  Future<void> prefetchEventsForSite(String siteId) async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<List<EcoEvent>> fetchEventsSnapshot(EcoEventSearchParams params) async {
    Iterable<EcoEvent> out = _events;
    if (params.statuses.isNotEmpty) {
      out = out.where((EcoEvent e) => params.statuses.contains(e.status));
    }
    if (params.dateFrom != null && params.dateTo != null) {
      final DateTime f = DateTime(
        params.dateFrom!.year,
        params.dateFrom!.month,
        params.dateFrom!.day,
      );
      final DateTime t = DateTime(
        params.dateTo!.year,
        params.dateTo!.month,
        params.dateTo!.day,
      );
      out = out.where((EcoEvent e) {
        final DateTime d = DateTime(e.date.year, e.date.month, e.date.day);
        return !d.isBefore(f) && !d.isAfter(t);
      });
    }
    if (params.categories.isNotEmpty) {
      out = out.where((EcoEvent e) => params.categories.contains(e.category));
    }
    if (params.query != null && params.query!.trim().isNotEmpty) {
      final String q = params.query!.trim().toLowerCase();
      out = out.where(
        (EcoEvent e) =>
            e.title.toLowerCase().contains(q) || e.siteName.toLowerCase().contains(q),
      );
    }
    final List<EcoEvent> list = out.toList()
      ..sort((EcoEvent a, EcoEvent b) {
        final int dist = a.siteDistanceKm.compareTo(b.siteDistanceKm);
        if (dist != 0) {
          return dist;
        }
        return a.startDateTime.compareTo(b.startDateTime);
      });
    return list;
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
  Future<EcoEvent> create(EcoEvent event) async {
    _events = <EcoEvent>[event, ..._events];
    notifyListeners();
    _persistSnapshot();
    return event;
  }

  @override
  Future<EventScheduleConflictPreview> checkScheduleConflict({
    required String siteId,
    required DateTime scheduledAt,
    DateTime? endAt,
    String? excludeEventId,
  }) async =>
      const EventScheduleConflictPreview(hasConflict: false);

  @override
  Future<EcoEvent> updateEventDetails(
    String eventId,
    EventUpdatePayload payload,
  ) async {
    final EcoEvent? current = findById(eventId);
    if (current == null) {
      throw AppError.notFound();
    }
    final Map<String, dynamic> patch = payload.toPatchJson();
    EcoEvent next = current;
    if (patch.containsKey('title')) {
      next = next.copyWith(title: patch['title'] as String);
    }
    if (patch.containsKey('description')) {
      next = next.copyWith(description: patch['description'] as String);
    }
    if (patch.containsKey('category')) {
      final String name = patch['category'] as String;
      final EcoEventCategory cat = EcoEventCategory.values.firstWhere(
        (EcoEventCategory c) => c.name == name,
        orElse: () => next.category,
      );
      next = next.copyWith(category: cat);
    }
    if (patch.containsKey('scheduledAt')) {
      final DateTime start =
          DateTime.parse(patch['scheduledAt'] as String).toLocal();
      next = next.copyWith(
        date: DateTime(start.year, start.month, start.day),
        startTime: EventTime(hour: start.hour, minute: start.minute),
      );
    }
    if (patch.containsKey('endAt') && patch['endAt'] != null) {
      final DateTime end = DateTime.parse(patch['endAt'] as String).toLocal();
      next = next.copyWith(
        endTime: EventTime(hour: end.hour, minute: end.minute),
      );
    }
    if (patch.containsKey('maxParticipants')) {
      final Object? raw = patch['maxParticipants'];
      if (raw == null) {
        next = next.copyWith(clearMaxParticipants: true);
      } else {
        next = next.copyWith(maxParticipants: raw as int);
      }
    }
    if (patch.containsKey('gear')) {
      final List<dynamic> raw = patch['gear'] as List<dynamic>;
      final List<EventGear> gear = raw
          .map((dynamic g) => EventGear.values.firstWhere(
                (EventGear x) => x.name == g,
                orElse: () => EventGear.trashBags,
              ))
          .toSet()
          .toList(growable: false);
      next = next.copyWith(gear: gear);
    }
    if (patch.containsKey('scale')) {
      final String name = patch['scale'] as String;
      next = next.copyWith(
        scale: CleanupScale.values.firstWhere(
          (CleanupScale s) => s.name == name,
          orElse: () => next.scale ?? CleanupScale.small,
        ),
      );
    }
    if (patch.containsKey('difficulty')) {
      final String name = patch['difficulty'] as String;
      next = next.copyWith(
        difficulty: EventDifficulty.values.firstWhere(
          (EventDifficulty d) => d.name == name,
          orElse: () => next.difficulty ?? EventDifficulty.easy,
        ),
      );
    }
    _events = _events
        .map((EcoEvent e) => e.id == eventId ? next : e)
        .toList(growable: false);
    notifyListeners();
    _persistSnapshot();
    return next;
  }

  @override
  Future<bool> updateStatus(String id, EcoEventStatus status) async {
    bool changed = false;
    _events = _events.map((EcoEvent event) {
      if (event.id != id) {
        return event;
      }
      if (!event.canTransitionTo(status)) {
        return event;
      }
      if (status == EcoEventStatus.inProgress && event.isBeforeScheduledStart) {
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
  Future<EcoEventJoinToggleResult> toggleJoin(String id) async {
    bool changed = false;
    _events = _events.map((EcoEvent event) {
      if (event.id != id || !event.isJoinable) {
        return event;
      }
      if (!event.isJoined && event.maxParticipants != null && event.participantCount >= event.maxParticipants!) {
        return event;
      }
      if (!event.isJoined && !event.canVolunteerJoinNow) {
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
    return EcoEventJoinToggleResult(changed: changed);
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
  Future<bool> setReminder({
    required String eventId,
    required bool enabled,
    DateTime? reminderAt,
  }) async {
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
  Future<bool> setAfterImages({
    required String eventId,
    required List<String> imagePaths,
  }) async {
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

  @override
  Future<EventParticipantsPage> fetchParticipants(String eventId, {String? cursor}) async {
    final EcoEvent? event = findById(eventId);
    final int n = event?.participantCount ?? 0;
    final String? c = cursor?.trim();
    if (c != null && c.isNotEmpty) {
      return const EventParticipantsPage(items: <EventParticipantRow>[], hasMore: false);
    }
    final List<EventParticipantRow> items = List<EventParticipantRow>.generate(
      n,
      (int i) => EventParticipantRow(
        userId: 'in_memory_volunteer_$i',
        displayName: 'Volunteer ${i + 1}',
        joinedAt: DateTime.fromMillisecondsSinceEpoch(1000 * i, isUtc: true),
        avatarUrl: null,
      ),
    );
    return EventParticipantsPage(items: items, hasMore: false);
  }

  Future<void> _hydrateFromCache() async {
    try {
      final List<EcoEvent>? cached = await _localCache.readEvents(
        forActiveListParams: null,
      );
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
    unawaited(_localCache.writeEvents(_events, forActiveListParams: null));
  }
}
