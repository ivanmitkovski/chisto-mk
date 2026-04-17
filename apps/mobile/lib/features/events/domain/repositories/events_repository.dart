import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_join_toggle_result.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/models/event_schedule_conflict_preview.dart';
import 'package:chisto_mobile/features/events/domain/models/event_update_payload.dart';
import 'package:flutter/foundation.dart';

abstract class EventsRepository implements Listenable {
  List<EcoEvent> get events;

  /// Last time a list page fetch completed successfully ([refreshEvents] / [loadMore]).
  /// Null when unknown (tests); used for optional tab-revisit refresh throttling.
  DateTime? get lastSuccessfulListRefreshAt;

  /// Whether more pages can be loaded ([loadMore]). Always false for in-memory store.
  bool get hasMoreEvents;

  bool get isReady;
  Future<void> get ready;

  /// True after the last global list fetch failed ([refreshEvents] or initial bootstrap).
  /// Always false for [InMemoryEventsStore].
  bool get lastGlobalListLoadFailed;

  /// True when [events] comes from disk cache after a failed network refresh/bootstrap.
  bool get isShowingStaleCachedEvents;

  void loadInitialIfNeeded();

  /// Full reload from network (pull-to-refresh). No-op for in-memory dev store.
  ///
  /// When [params] is provided, the fetch applies server-side filters/search.
  /// Passing null reverts to the global unfiltered list.
  Future<void> refreshEvents({EcoEventSearchParams? params});

  /// Loads [id] into [events] when missing (deep links / cold cache).
  ///
  /// When [force] is true, implementations should refresh from the canonical
  /// source even if the event is already cached locally.
  Future<bool> prefetchEvent(String id, {bool force = false});

  /// Merges `GET /events?siteId=…` into [events] (API-backed only; no-op in memory).
  Future<void> prefetchEventsForSite(String siteId);

  void resetToSeed();

  EcoEvent? findById(String id);
  EcoEvent? findBySiteAndTitle({
    required String siteId,
    required String title,
  });

  /// Persists a new event; returns the canonical record (server id when using API).
  Future<EcoEvent> create(EcoEvent event);

  /// Organizer-only partial update (`PATCH /events/:id`).
  Future<EcoEvent> updateEventDetails(String eventId, EventUpdatePayload payload);

  /// Read-only overlap check (`GET /events/check-conflict`). In-memory store returns no conflict.
  Future<EventScheduleConflictPreview> checkScheduleConflict({
    required String siteId,
    required DateTime scheduledAt,
    DateTime? endAt,
    String? excludeEventId,
  });

  Future<bool> updateStatus(String id, EcoEventStatus status);

  Future<EcoEventJoinToggleResult> toggleJoin(String id);

  bool setCheckInOpen({
    required String eventId,
    required bool isOpen,
  });

  bool rotateCheckInSession({
    required String eventId,
    required String sessionId,
  });

  bool setCheckedInCount({
    required String eventId,
    required int checkedInCount,
  });

  bool setAttendeeCheckInStatus({
    required String eventId,
    required AttendeeCheckInStatus status,
    DateTime? checkedInAt,
  });

  Future<bool> setReminder({
    required String eventId,
    required bool enabled,
    DateTime? reminderAt,
  });

  Future<bool> setAfterImages({
    required String eventId,
    required List<String> imagePaths,
  });

  /// Append more list items when [hasMore] (API-backed stores only).
  Future<void> loadMore();

  /// Paginated joiners from `GET /events/:id/participants` (organizer not included).
  Future<EventParticipantsPage> fetchParticipants(String eventId, {String? cursor});
}
