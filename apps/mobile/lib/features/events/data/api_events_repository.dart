import 'dart:async';
import 'dart:collection';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/event_json.dart';
import 'package:chisto_mobile/features/events/data/participants_json.dart';
import 'package:chisto_mobile/features/events/data/events_local_cache.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_join_toggle_result.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/models/event_update_payload.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:flutter/foundation.dart';

/// Server-backed [EventsRepository] using `/events` REST endpoints.
class ApiEventsRepository extends ChangeNotifier implements EventsRepository {
  ApiEventsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;
  final EventsLocalCache _cache = const EventsLocalCache();

  List<EcoEvent> _events = <EcoEvent>[];
  Completer<void>? _readyCompleter;
  bool _started = false;
  String? _nextCursor;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _lastGlobalListLoadFailed = false;
  bool _isShowingStaleCachedEvents = false;

  @override
  bool get hasMoreEvents => _hasMore;

  @override
  bool get lastGlobalListLoadFailed => _lastGlobalListLoadFailed;

  @override
  bool get isShowingStaleCachedEvents => _isShowingStaleCachedEvents;

  @override
  List<EcoEvent> get events => List<EcoEvent>.unmodifiable(_events);

  @override
  bool get isReady => _readyCompleter?.isCompleted ?? false;

  @override
  Future<void> get ready =>
      _readyCompleter?.future ?? Future<void>.value();

  @override
  void loadInitialIfNeeded() {
    if (_started) {
      return;
    }
    _started = true;
    _readyCompleter = Completer<void>();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      await _fetchPage(replace: true);
      await _cache.writeEvents(_events);
      _lastGlobalListLoadFailed = false;
      _isShowingStaleCachedEvents = false;
    } on Object catch (_) {
      _lastGlobalListLoadFailed = true;
      final List<EcoEvent>? stale = await _cache.readEvents();
      if (stale != null && stale.isNotEmpty) {
        _events = stale;
        _isShowingStaleCachedEvents = true;
        notifyListeners();
      } else {
        _isShowingStaleCachedEvents = false;
      }
    } finally {
      _readyCompleter?.complete();
    }
  }

  EcoEventSearchParams? _activeParams;

  /// Builds the `/events` path including all active server-side filter params.
  String _globalListPath({String? cursor, EcoEventSearchParams? params}) {
    final StringBuffer path = StringBuffer('/events?limit=50');
    final String? c = cursor?.trim();
    if (c != null && c.isNotEmpty) {
      path.write('&cursor=${Uri.encodeQueryComponent(c)}');
    }
    final EcoEventSearchParams? p = params ?? _activeParams;
    if (p != null) {
      final String? q = p.query?.trim();
      if (q != null && q.isNotEmpty) {
        path.write('&q=${Uri.encodeQueryComponent(q)}');
      }
      if (p.categories.isNotEmpty) {
        final List<String> categoryKeys = p.categories
            .map((EcoEventCategory c) => c.key)
            .toList(growable: false)
          ..sort();
        path.write('&category=${Uri.encodeQueryComponent(categoryKeys.join(','))}');
      }
      if (p.statuses.isNotEmpty) {
        final List<String> statusKeys = p.statuses
            .map((EcoEventStatus s) => s.apiKey)
            .toList(growable: false)
          ..sort();
        path.write('&status=${Uri.encodeQueryComponent(statusKeys.join(','))}');
      }
      if (p.dateFrom != null) {
        final String df =
            '${p.dateFrom!.year.toString().padLeft(4, '0')}-'
            '${p.dateFrom!.month.toString().padLeft(2, '0')}-'
            '${p.dateFrom!.day.toString().padLeft(2, '0')}';
        path.write('&dateFrom=${Uri.encodeQueryComponent(df)}');
      }
      if (p.dateTo != null) {
        final String dt =
            '${p.dateTo!.year.toString().padLeft(4, '0')}-'
            '${p.dateTo!.month.toString().padLeft(2, '0')}-'
            '${p.dateTo!.day.toString().padLeft(2, '0')}';
        path.write('&dateTo=${Uri.encodeQueryComponent(dt)}');
      }
    }
    return path.toString();
  }

  Future<void> _fetchPage({
    required bool replace,
    String? cursor,
    EcoEventSearchParams? params,
  }) async {
    final ApiResponse response = await _client.get(
      _globalListPath(cursor: cursor, params: params),
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }

    final List<dynamic> raw = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<EcoEvent> page = ecoEventListFromJson(raw);
    final Object? metaRaw = json['meta'];
    final Map<String, dynamic> meta = metaRaw is Map<String, dynamic>
        ? metaRaw
        : <String, dynamic>{};
    final String? next = meta['nextCursor'] as String?;
    final bool hasMore = meta['hasMore'] == true;

    if (replace) {
      _events = page;
    } else {
      final LinkedHashSet<String> ids = LinkedHashSet<String>.from(
        _events.map((EcoEvent e) => e.id),
      );
      final List<EcoEvent> merged = List<EcoEvent>.from(_events);
      for (final EcoEvent e in page) {
        if (ids.add(e.id)) {
          merged.add(e);
        }
      }
      _events = merged;
    }
    _nextCursor = next;
    _hasMore = hasMore;
    notifyListeners();
  }

  @override
  Future<void> refreshEvents({EcoEventSearchParams? params}) async {
    // When params change, reset pagination state.
    if (params != _activeParams) {
      _activeParams = params;
      _nextCursor = null;
      _hasMore = false;
    }
    try {
      await _fetchPage(replace: true, params: params);
      // Only persist unfiltered lists to the disk cache.
      if (params == null || params.isEmpty) {
        await _cache.writeEvents(_events);
      }
      _lastGlobalListLoadFailed = false;
      _isShowingStaleCachedEvents = false;
      notifyListeners();
    } on Object catch (e, st) {
      _lastGlobalListLoadFailed = true;
      if (_events.isNotEmpty) {
        _isShowingStaleCachedEvents = true;
      }
      notifyListeners();
      if (e is AppError) {
        Error.throwWithStackTrace(e, st);
      }
      Error.throwWithStackTrace(AppError.unknown(cause: e), st);
    }
  }

  @override
  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) {
      return;
    }
    final String? c = _nextCursor;
    if (c == null || c.isEmpty) {
      return;
    }
    _loadingMore = true;
    try {
      // Preserve active params so paginated pages stay filtered.
      await _fetchPage(replace: false, cursor: c, params: _activeParams);
      if (_activeParams == null || _activeParams!.isEmpty) {
        await _cache.writeEvents(_events);
      }
    } finally {
      _loadingMore = false;
    }
  }

  @override
  Future<bool> prefetchEvent(String id, {bool force = false}) async {
    if (!force && findById(id) != null) {
      return true;
    }
    try {
      final ApiResponse response = await _client.get('/events/$id');
      final Map<String, dynamic>? json = response.json;
      if (json == null) {
        return false;
      }
      final EcoEvent event = ecoEventFromJson(json);
      _upsert(event);
      notifyListeners();
      await _cache.writeEvents(_events);
      return true;
    } on AppError catch (e) {
      if (e.code == 'NOT_FOUND') {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<EventParticipantsPage> fetchParticipants(String eventId, {String? cursor}) async {
    final StringBuffer path = StringBuffer('/events/$eventId/participants?limit=50');
    final String? c = cursor?.trim();
    if (c != null && c.isNotEmpty) {
      path.write('&cursor=${Uri.encodeQueryComponent(c)}');
    }
    final ApiResponse response = await _client.get(path.toString());
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    return eventParticipantsPageFromJson(json);
  }

  void _upsert(EcoEvent event) {
    final List<EcoEvent> next = _events
        .where((EcoEvent e) => e.id != event.id)
        .toList(growable: true);
    next.insert(0, event);
    _events = next;
  }

  /// Updates existing rows by id and appends events not yet in the list (stable order).
  void _mergeListPage(List<EcoEvent> page) {
    if (page.isEmpty) {
      return;
    }
    final Map<String, EcoEvent> byId = <String, EcoEvent>{
      for (final EcoEvent e in _events) e.id: e,
    };
    for (final EcoEvent e in page) {
      byId[e.id] = e;
    }
    final List<EcoEvent> order = <EcoEvent>[];
    final Set<String> seen = <String>{};
    for (final EcoEvent e in _events) {
      order.add(byId[e.id]!);
      seen.add(e.id);
    }
    for (final EcoEvent e in page) {
      if (!seen.contains(e.id)) {
        order.add(byId[e.id]!);
        seen.add(e.id);
      }
    }
    _events = order;
  }

  @override
  Future<void> prefetchEventsForSite(String siteId) async {
    final String id = siteId.trim();
    if (id.isEmpty) {
      return;
    }
    try {
      final ApiResponse response = await _client.get(
        '/events?siteId=${Uri.encodeQueryComponent(id)}&limit=50',
      );
      final Map<String, dynamic>? json = response.json;
      if (json == null) {
        return;
      }
      final List<dynamic> raw = json['data'] as List<dynamic>? ?? <dynamic>[];
      final List<EcoEvent> page = ecoEventListFromJson(raw);
      _mergeListPage(page);
      notifyListeners();
      await _cache.writeEvents(_events);
    } on Object {
      // Site tab still shows whatever the global list already had.
    }
  }

  @override
  Future<EcoEvent> updateEventDetails(
    String eventId,
    EventUpdatePayload payload,
  ) async {
    final Map<String, dynamic> body = payload.toPatchJson();
    if (body.isEmpty) {
      final EcoEvent? existing = findById(eventId);
      if (existing == null) {
        throw AppError.notFound();
      }
      return existing;
    }
    final ApiResponse response =
        await _client.patch('/events/$eventId', body: body);
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    final EcoEvent updated = ecoEventFromJson(json);
    _replaceById(eventId, updated);
    notifyListeners();
    await _cache.writeEvents(_events);
    return updated;
  }

  @override
  void resetToSeed() {
    _events = <EcoEvent>[];
    _nextCursor = null;
    _hasMore = false;
    _lastGlobalListLoadFailed = false;
    _isShowingStaleCachedEvents = false;
    notifyListeners();
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

  Map<String, dynamic> _createBody(EcoEvent event) {
    return <String, dynamic>{
      'siteId': event.siteId,
      'title': event.title,
      'description': event.description,
      'category': event.category.name,
      'scheduledAt': event.startDateTime.toUtc().toIso8601String(),
      'endAt': event.endDateTime.toUtc().toIso8601String(),
      if (event.maxParticipants != null) 'maxParticipants': event.maxParticipants,
      'gear': event.gear.map((EventGear g) => g.name).toList(growable: false),
      if (event.scale != null) 'scale': event.scale!.name,
      if (event.difficulty != null) 'difficulty': event.difficulty!.name,
    };
  }

  @override
  Future<EcoEvent> create(EcoEvent event) async {
    final ApiResponse response =
        await _client.post('/events', body: _createBody(event));
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    final EcoEvent created = ecoEventFromJson(json);
    _upsert(created);
    notifyListeners();
    await _cache.writeEvents(_events);
    return created;
  }

  @override
  Future<bool> updateStatus(String id, EcoEventStatus status) async {
    final EcoEvent? current = findById(id);
    if (current == null || !current.canTransitionTo(status)) {
      return false;
    }

    final List<EcoEvent> previous = List<EcoEvent>.from(_events);
    EcoEvent draft = current;
    if (status == EcoEventStatus.inProgress) {
      draft = current.copyWith(status: status);
    } else {
      draft = current.copyWith(
        status: status,
        isCheckInOpen: false,
        clearActiveCheckInSessionId: true,
      );
    }
    _replaceById(id, draft);
    notifyListeners();

    try {
      await _client.patch(
        '/events/$id/status',
        body: <String, dynamic>{'status': status.name},
      );
      final ApiResponse refreshed = await _client.get('/events/$id');
      final Map<String, dynamic>? json = refreshed.json;
      if (json != null) {
        _replaceById(id, ecoEventFromJson(json));
        notifyListeners();
      }
      await _cache.writeEvents(_events);
      return true;
    } on AppError {
      _events = previous;
      notifyListeners();
      rethrow;
    } on Object catch (e, st) {
      _events = previous;
      notifyListeners();
      Error.throwWithStackTrace(AppError.unknown(cause: e), st);
    }
  }

  void _replaceById(String id, EcoEvent next) {
    _events = _events
        .map((EcoEvent e) => e.id == id ? next : e)
        .toList(growable: false);
  }

  @override
  Future<EcoEventJoinToggleResult> toggleJoin(String id) async {
    final EcoEvent? event = findById(id);
    if (event == null || !event.isJoinable) {
      return const EcoEventJoinToggleResult(changed: false);
    }
    if (!event.isJoined &&
        event.maxParticipants != null &&
        event.participantCount >= event.maxParticipants!) {
      return const EcoEventJoinToggleResult(changed: false);
    }

    final List<EcoEvent> previous = List<EcoEvent>.from(_events);
    final bool nextJoined = !event.isJoined;
    final int nextCount = nextJoined
        ? event.participantCount + 1
        : (event.participantCount - 1).clamp(0, 1000000);
    _replaceById(
      id,
      event.copyWith(
        isJoined: nextJoined,
        participantCount: nextCount,
      ),
    );
    notifyListeners();

    try {
      int pointsAwarded = 0;
      if (nextJoined) {
        final ApiResponse joinResp = await _client.post('/events/$id/join');
        pointsAwarded = parsePointsAwardedFromJson(joinResp.json);
      } else {
        await _client.delete('/events/$id/join');
      }
      final ApiResponse refreshed = await _client.get('/events/$id');
      final Map<String, dynamic>? json = refreshed.json;
      if (json != null) {
        _replaceById(id, ecoEventFromJson(json));
        notifyListeners();
      }
      await _cache.writeEvents(_events);
      return EcoEventJoinToggleResult(changed: true, pointsAwarded: pointsAwarded);
    } on AppError {
      _events = previous;
      notifyListeners();
      rethrow;
    } on Object catch (e, st) {
      _events = previous;
      notifyListeners();
      Error.throwWithStackTrace(AppError.unknown(cause: e), st);
    }
  }

  @override
  bool setCheckInOpen({
    required String eventId,
    required bool isOpen,
  }) {
    final EcoEvent? current = findById(eventId);
    if (current == null) {
      return false;
    }
    if (current.isCheckInOpen == isOpen) {
      return false;
    }
    _replaceById(eventId, current.copyWith(isCheckInOpen: isOpen));
    notifyListeners();
    unawaited(_cache.writeEvents(_events));
    return true;
  }

  @override
  bool rotateCheckInSession({
    required String eventId,
    required String sessionId,
  }) {
    final EcoEvent? current = findById(eventId);
    if (current == null) {
      return false;
    }
    if (current.activeCheckInSessionId == sessionId) {
      return false;
    }
    _replaceById(
      eventId,
      current.copyWith(activeCheckInSessionId: sessionId),
    );
    notifyListeners();
    unawaited(_cache.writeEvents(_events));
    return true;
  }

  @override
  bool setCheckedInCount({
    required String eventId,
    required int checkedInCount,
  }) {
    return false;
  }

  @override
  bool setAttendeeCheckInStatus({
    required String eventId,
    required AttendeeCheckInStatus status,
    DateTime? checkedInAt,
  }) {
    return false;
  }

  @override
  Future<bool> setReminder({
    required String eventId,
    required bool enabled,
    DateTime? reminderAt,
  }) async {
    final EcoEvent? event = findById(eventId);
    if (event == null) {
      return false;
    }
    if (event.reminderEnabled == enabled && event.reminderAt == reminderAt) {
      return true;
    }

    final List<EcoEvent> previous = List<EcoEvent>.from(_events);
    _replaceById(
      eventId,
      event.copyWith(
        reminderEnabled: enabled,
        reminderAt: reminderAt,
        clearReminderAt: !enabled || reminderAt == null,
      ),
    );
    notifyListeners();

    try {
      await _client.patch(
        '/events/$eventId/reminder',
        body: <String, dynamic>{
          'reminderEnabled': enabled,
          if (enabled && reminderAt != null)
            'reminderAt': reminderAt.toUtc().toIso8601String()
          else
            'reminderAt': null,
        },
      );
      final ApiResponse refreshed = await _client.get('/events/$eventId');
      final Map<String, dynamic>? json = refreshed.json;
      if (json != null) {
        _replaceById(eventId, ecoEventFromJson(json));
        notifyListeners();
      }
      await _cache.writeEvents(_events);
      return true;
    } on AppError {
      _events = previous;
      notifyListeners();
      rethrow;
    } on Object catch (e, st) {
      _events = previous;
      notifyListeners();
      Error.throwWithStackTrace(AppError.unknown(cause: e), st);
    }
  }

  @override
  Future<bool> setAfterImages({
    required String eventId,
    required List<String> imagePaths,
  }) async {
    final EcoEvent? event = findById(eventId);
    if (event == null || imagePaths.isEmpty) {
      return false;
    }

    final List<EcoEvent> previous = List<EcoEvent>.from(_events);
    final List<String> normalized =
        LinkedHashSet<String>.from(imagePaths).toList(growable: false);
    _replaceById(eventId, event.copyWith(afterImagePaths: normalized));
    notifyListeners();

    try {
      final List<String> pathsForUpload = imagePaths
          .map((String p) => p.trim())
          .where((String p) => p.isNotEmpty)
          .where((String p) => !_isHttpOrHttpsUrl(p))
          .where((String p) => !p.startsWith('assets/'))
          .toList(growable: false);
      if (pathsForUpload.isNotEmpty) {
        await _client.postMultipart('/events/$eventId/after-images', pathsForUpload);
      }
      final ApiResponse refreshed = await _client.get('/events/$eventId');
      final Map<String, dynamic>? json = refreshed.json;
      if (json != null) {
        _replaceById(eventId, ecoEventFromJson(json));
        notifyListeners();
      }
      await _cache.writeEvents(_events);
      return true;
    } on AppError {
      _events = previous;
      notifyListeners();
      rethrow;
    } on Object catch (e, st) {
      _events = previous;
      notifyListeners();
      Error.throwWithStackTrace(AppError.unknown(cause: e), st);
    }
  }
}

bool _isHttpOrHttpsUrl(String raw) {
  final String t = raw.trim().toLowerCase();
  return t.startsWith('http://') || t.startsWith('https://');
}
