import 'dart:async';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_join_toggle_result.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/models/event_schedule_conflict_preview.dart';
import 'package:chisto_mobile/features/events/domain/models/event_update_payload.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:flutter/foundation.dart';

/// Minimal [EventsRepository] for unit tests: records calls to key methods.
class RecordingEventsRepository extends ChangeNotifier implements EventsRepository {
  RecordingEventsRepository({List<EcoEvent>? seed})
      : _events = List<EcoEvent>.from(seed ?? const <EcoEvent>[]);

  List<EcoEvent> _events;
  EcoEventSearchParams? lastRefreshParams;
  int refreshCallCount = 0;
  bool refreshShouldThrow = false;

  int toggleJoinCallCount = 0;
  String? lastToggleJoinId;

  EventScheduleConflictPreview? scheduleConflictOverride;
  AppError? updateEventDetailsError;
  EventUpdatePayload? lastUpdateEventDetailsPayload;
  int updateEventDetailsCallCount = 0;

  int updateStatusCallCount = 0;
  String? lastUpdateStatusId;
  EcoEventStatus? lastUpdateStatusValue;

  int prefetchEventCallCount = 0;
  String? lastPrefetchEventId;

  int setAttendeeCheckInStatusCallCount = 0;
  String? lastSetAttendeeCheckInStatusEventId;
  AttendeeCheckInStatus? lastSetAttendeeCheckInStatusValue;
  DateTime? lastSetAttendeeCheckInStatusAt;

  int createCallCount = 0;
  EcoEvent? lastCreatedEvent;

  @override
  List<EcoEvent> get events => List<EcoEvent>.unmodifiable(_events);

  @override
  List<String> get lastRankedSearchSuggestions => const <String>[];

  @override
  DateTime? get lastSuccessfulListRefreshAt => null;

  bool _hasMoreForTest = false;

  /// Test-only: when true, [loadMore] increments [loadMoreCallCount] and notifies.
  set hasMoreForTest(bool v) => _hasMoreForTest = v;

  int loadMoreCallCount = 0;

  @override
  bool get hasMoreEvents => _hasMoreForTest;

  @override
  bool get isReady => true;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  bool get lastGlobalListLoadFailed => false;

  @override
  bool get isShowingStaleCachedEvents => false;

  @override
  void loadInitialIfNeeded() {}

  @override
  Future<void> refreshEvents({EcoEventSearchParams? params}) async {
    refreshCallCount++;
    lastRefreshParams = params;
    if (refreshShouldThrow) {
      throw AppError.network(message: 'test');
    }
    notifyListeners();
  }

  @override
  Future<bool> prefetchEvent(String id, {bool force = false}) async {
    prefetchEventCallCount++;
    lastPrefetchEventId = id;
    return findById(id) != null;
  }

  @override
  Future<void> prefetchEventsForSite(String siteId) async {}

  @override
  void resetToSeed() {
    _events = <EcoEvent>[];
    notifyListeners();
  }

  @override
  EcoEvent? findById(String id) {
    for (final EcoEvent e in _events) {
      if (e.id == id) {
        return e;
      }
    }
    return null;
  }

  @override
  EcoEvent? findBySiteAndTitle({
    required String siteId,
    required String title,
  }) =>
      null;

  @override
  Future<EcoEvent> create(EcoEvent event) async {
    createCallCount++;
    lastCreatedEvent = event;
    return event;
  }

  @override
  Future<EventScheduleConflictPreview> checkScheduleConflict({
    required String siteId,
    required DateTime scheduledAt,
    DateTime? endAt,
    String? excludeEventId,
  }) async =>
      scheduleConflictOverride ?? const EventScheduleConflictPreview(hasConflict: false);

  @override
  Future<EcoEvent> updateEventDetails(
    String eventId,
    EventUpdatePayload payload,
  ) async {
    updateEventDetailsCallCount++;
    lastUpdateEventDetailsPayload = payload;
    final AppError? err = updateEventDetailsError;
    if (err != null) {
      throw err;
    }
    final EcoEvent? e = findById(eventId);
    if (e == null) {
      throw AppError.notFound();
    }
    return e;
  }

  @override
  Future<bool> updateStatus(String id, EcoEventStatus status) async {
    updateStatusCallCount++;
    lastUpdateStatusId = id;
    lastUpdateStatusValue = status;
    return false;
  }

  @override
  Future<EcoEventJoinToggleResult> toggleJoin(String id) async {
    toggleJoinCallCount++;
    lastToggleJoinId = id;
    return const EcoEventJoinToggleResult(changed: false);
  }

  @override
  bool setCheckInOpen({
    required String eventId,
    required bool isOpen,
  }) =>
      false;

  @override
  bool rotateCheckInSession({
    required String eventId,
    required String sessionId,
  }) =>
      false;

  @override
  bool setCheckedInCount({
    required String eventId,
    required int checkedInCount,
  }) =>
      false;

  @override
  bool setAttendeeCheckInStatus({
    required String eventId,
    required AttendeeCheckInStatus status,
    DateTime? checkedInAt,
  }) {
    setAttendeeCheckInStatusCallCount++;
    lastSetAttendeeCheckInStatusEventId = eventId;
    lastSetAttendeeCheckInStatusValue = status;
    lastSetAttendeeCheckInStatusAt = checkedInAt;
    return true;
  }

  @override
  Future<bool> setReminder({
    required String eventId,
    required bool enabled,
    DateTime? reminderAt,
  }) async =>
      false;

  @override
  Future<bool> setAfterImages({
    required String eventId,
    required List<String> imagePaths,
  }) async =>
      false;

  @override
  Future<void> loadMore() async {
    if (!_hasMoreForTest) {
      return;
    }
    loadMoreCallCount++;
    notifyListeners();
  }

  int fetchEventsSnapshotCallCount = 0;
  EcoEventSearchParams? lastSnapshotParams;

  /// When non-null, [fetchParticipants] returns this page (cursor ignored).
  EventParticipantsPage? participantsPageStub;

  int fetchParticipantsCallCount = 0;

  @override
  Future<List<EcoEvent>> fetchEventsSnapshot(EcoEventSearchParams params) async {
    fetchEventsSnapshotCallCount++;
    lastSnapshotParams = params;
    return _events
        .where((EcoEvent e) {
          if (params.statuses.isNotEmpty && !params.statuses.contains(e.status)) {
            return false;
          }
          return true;
        })
        .toList();
  }

  @override
  Future<EventParticipantsPage> fetchParticipants(
    String eventId, {
    String? cursor,
  }) async {
    fetchParticipantsCallCount++;
    return participantsPageStub ??
        const EventParticipantsPage(items: <EventParticipantRow>[], hasMore: false);
  }
}
