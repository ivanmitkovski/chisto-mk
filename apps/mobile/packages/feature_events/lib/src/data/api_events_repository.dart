library;

import 'dart:async';
import 'dart:collection';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:feature_events/src/data/api_events_ranked_search.dart';
import 'package:feature_events/src/data/event_impact_receipt_json.dart';
import 'package:feature_events/src/data/event_json.dart';
import 'package:feature_events/src/data/events_local_cache.dart';
import 'package:feature_events/src/data/participants_json.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_join_toggle_result.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:feature_events/src/domain/models/events_list_page_snapshot.dart';
import 'package:feature_events/src/domain/models/event_impact_receipt.dart';
import 'package:feature_events/src/domain/models/event_participant_row.dart';
import 'package:feature_events/src/domain/models/event_schedule_conflict_preview.dart';
import 'package:feature_events/src/domain/models/event_update_payload.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/utils/events_diagnostic_log.dart';
import 'package:flutter/foundation.dart';

part 'api_events_repository_base.dart';
part 'api_events_repository_mutations.dart';

/// Server-backed [EventsRepository] using `/events` REST endpoints.
class ApiEventsRepository extends _ApiEventsRepositoryBase
    with ApiEventsRepositoryMutations
    implements EventsRepository {
  ApiEventsRepository({required super.client});

  @override
  DateTime? get lastSuccessfulListRefreshAt => _lastSuccessfulListRefreshAt;

  @override
  bool get hasMoreEvents => _hasMore;

  @override
  bool get lastGlobalListLoadFailed => _lastGlobalListLoadFailed;

  @override
  bool get isShowingStaleCachedEvents => _isShowingStaleCachedEvents;

  @override
  List<EcoEvent> get events => List<EcoEvent>.unmodifiable(_events);

  @override
  List<String> get lastRankedSearchSuggestions =>
      List<String>.unmodifiable(_lastRankedSearchSuggestions);

  @override
  bool get isReady => _readyCompleter?.isCompleted ?? false;

  @override
  Future<void> get ready => _readyCompleter?.future ?? Future<void>.value();

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
      await _persistEventsDisk();
      _lastGlobalListLoadFailed = false;
      _isShowingStaleCachedEvents = false;
    } on Object catch (e, st) {
      if (_isSessionInvalidFailure(e)) {
        if (e is AppError) {
          Error.throwWithStackTrace(e, st);
        }
        rethrow;
      }
      _lastGlobalListLoadFailed = true;
      final List<EcoEvent>? stale = await _cache.readEvents(
        forActiveListParams: null,
      );
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
        final List<String> categoryKeys =
            p.categories
                .map((EcoEventCategory c) => c.key)
                .toList(growable: false)
              ..sort();
        path.write(
          '&category=${Uri.encodeQueryComponent(categoryKeys.join(','))}',
        );
      }
      if (p.statuses.isNotEmpty) {
        final List<String> statusKeys =
            p.statuses
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
    if (_userLatitudeHint != null && _userLongitudeHint != null) {
      path.write('&nearLat=${_userLatitudeHint!.toStringAsFixed(6)}');
      path.write('&nearLng=${_userLongitudeHint!.toStringAsFixed(6)}');
    }
    return path.toString();
  }

  void setUserLocationHint({
    required double latitude,
    required double longitude,
  }) {
    final bool firstHint =
        _userLatitudeHint == null || _userLongitudeHint == null;
    _userLatitudeHint = latitude;
    _userLongitudeHint = longitude;
    if (firstHint &&
        _started &&
        (_readyCompleter?.isCompleted ?? false) &&
        !_lastListFetchIncludedLocationHint &&
        _events.isNotEmpty) {
      unawaited(_refreshListAfterLocationHint());
    }
  }

  Future<void> _refreshListAfterLocationHint() async {
    try {
      await refreshEvents(params: _activeParams);
    } on Object catch (_) {
      // Keep the current list; cards can still show client-side distance.
    }
  }

  List<EcoEvent> _eventsFromListResponse(ApiResponse response) {
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    final List<dynamic> raw = safeAsList(json['data']) ?? <dynamic>[];
    return ecoEventListFromJson(raw);
  }

  Future<void> _fetchPage({
    required bool replace,
    String? cursor,
    EcoEventSearchParams? params,
  }) async {
    final EcoEventSearchParams? p = params ?? _activeParams;
    final String? q = p?.query?.trim();
    final bool useRankedPost =
        replace &&
        (cursor == null || cursor.isEmpty) &&
        p != null &&
        q != null &&
        q.length >= 2;

    late final ApiResponse response;
    if (useRankedPost) {
      response = await _client.post(
        '/events/search',
        body: buildRankedEventsSearchBody(
          params: p,
          nearLat: _userLatitudeHint,
          nearLng: _userLongitudeHint,
        ),
      );
      _lastRankedSearchSuggestions = parseRankedSearchSuggestions(
        response.json,
      );
    } else {
      response = await _client.get(
        _globalListPath(cursor: cursor, params: params),
      );
      if (replace) {
        _lastRankedSearchSuggestions = const <String>[];
      }
    }
    final List<EcoEvent> page = _eventsFromListResponse(response);
    final Map<String, dynamic> json = response.json!;
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
    _lastSuccessfulListRefreshAt = DateTime.now();
    _lastListFetchIncludedLocationHint =
        _userLatitudeHint != null && _userLongitudeHint != null;
    notifyListeners();
  }

  @override
  Future<List<EcoEvent>> fetchEventsSnapshot(
    EcoEventSearchParams params,
  ) async {
    final EventsListPageSnapshot preview = await fetchEventsFilterPreview(
      params,
    );
    return preview.events;
  }

  @override
  Future<EventsListPageSnapshot> fetchEventsFilterPreview(
    EcoEventSearchParams params,
  ) async {
    final ApiResponse response = await _client.get(
      _globalListPath(cursor: null, params: params),
    );
    final List<EcoEvent> events = _eventsFromListResponse(response);
    final Map<String, dynamic> json = response.json ?? <String, dynamic>{};
    final Object? metaRaw = json['meta'];
    final Map<String, dynamic> meta = metaRaw is Map<String, dynamic>
        ? metaRaw
        : <String, dynamic>{};
    final bool hasMore = meta['hasMore'] == true;
    return EventsListPageSnapshot(events: events, hasMore: hasMore);
  }

  @override
  Future<void> refreshEvents({EcoEventSearchParams? params}) async {
    if (_activeRefresh != null) {
      return _activeRefresh!;
    }
    final Future<void> work = _doRefreshEvents(params: params);
    _activeRefresh = work;
    try {
      await work;
    } finally {
      _activeRefresh = null;
    }
  }

  Future<void> _doRefreshEvents({EcoEventSearchParams? params}) async {
    if (params != _activeParams) {
      _stashActiveListSnapshot();
      _activeParams = params;
      if (_tryRestoreListSnapshot(params)) {
        notifyListeners();
      } else {
        _nextCursor = null;
        _hasMore = false;
      }
    }
    try {
      await _fetchPage(replace: true, params: params);
      await _persistEventsDisk();
      _stashActiveListSnapshot();
      _lastGlobalListLoadFailed = false;
      _isShowingStaleCachedEvents = false;
      notifyListeners();
    } on Object catch (e, st) {
      if (_isSessionInvalidFailure(e)) {
        if (e is AppError) {
          Error.throwWithStackTrace(e, st);
        }
        rethrow;
      }
      _lastGlobalListLoadFailed = true;
      await _tryHydrateFromDiskAfterListFailure(params);
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
      await _persistEventsDisk();
    } on Object catch (e, st) {
      if (_isSessionInvalidFailure(e)) {
        if (e is AppError) {
          Error.throwWithStackTrace(e, st);
        }
        rethrow;
      }
      _lastGlobalListLoadFailed = true;
      if (_events.isNotEmpty) {
        _isShowingStaleCachedEvents = true;
      }
      notifyListeners();
      if (e is AppError) {
        Error.throwWithStackTrace(e, st);
      }
      Error.throwWithStackTrace(AppError.unknown(cause: e), st);
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
      final EcoEvent? event = ecoEventFromJson(json);
      if (event == null) return false;
      _upsert(event);
      notifyListeners();
      await _persistEventsDisk();
      return true;
    } on AppError catch (e) {
      if (_isEventMissingError(e)) {
        _events = _events
            .where((EcoEvent e) => e.id != id)
            .toList(growable: false);
        notifyListeners();
        return false;
      }
      rethrow;
    }
  }

  bool _isEventMissingError(AppError error) {
    switch (error.code) {
      case 'NOT_FOUND':
      case 'EVENT_NOT_FOUND':
      case 'CLEANUP_EVENT_NOT_FOUND':
        return true;
      default:
        return false;
    }
  }

  @override
  Future<EventParticipantsPage> fetchParticipants(
    String eventId, {
    String? cursor,
  }) async {
    final StringBuffer path = StringBuffer(
      '/events/$eventId/participants?limit=50',
    );
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
      final List<dynamic> raw = safeAsList(json['data']) ?? <dynamic>[];
      final List<EcoEvent> page = ecoEventListFromJson(raw);
      _mergeListPage(page);
      notifyListeners();
      await _persistEventsDisk();
    } on Object catch (_) {
      logEventsDiagnostic('prefetch_events_for_site_failed');
    }
  }

  @override
  bool setCheckInOpen({required String eventId, required bool isOpen}) {
    final EcoEvent? current = findById(eventId);
    if (current == null) {
      return false;
    }
    if (current.isCheckInOpen == isOpen) {
      return false;
    }
    _replaceById(eventId, current.copyWith(isCheckInOpen: isOpen));
    notifyListeners();
    unawaited(_persistEventsDisk());
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
    _replaceById(eventId, current.copyWith(activeCheckInSessionId: sessionId));
    notifyListeners();
    unawaited(_persistEventsDisk());
    return true;
  }

  @override
  bool setCheckedInCount({
    required String eventId,
    required int checkedInCount,
  }) {
    final EcoEvent? current = findById(eventId);
    if (current == null) {
      return false;
    }
    if (current.checkedInCount == checkedInCount) {
      return false;
    }
    _replaceById(eventId, current.copyWith(checkedInCount: checkedInCount));
    notifyListeners();
    unawaited(_persistEventsDisk());
    return true;
  }

  @override
  bool setAttendeeCheckInStatus({
    required String eventId,
    required AttendeeCheckInStatus status,
    DateTime? checkedInAt,
  }) {
    final EcoEvent? current = findById(eventId);
    if (current == null) {
      return false;
    }
    if (current.attendeeCheckInStatus == status &&
        current.attendeeCheckedInAt == checkedInAt) {
      return false;
    }
    _replaceById(
      eventId,
      current.copyWith(
        attendeeCheckInStatus: status,
        attendeeCheckedInAt: checkedInAt,
        clearAttendeeCheckedInAt: checkedInAt == null,
      ),
    );
    notifyListeners();
    unawaited(_persistEventsDisk());
    return true;
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
    if (!_mutationsInFlight.add('setReminder:$eventId')) {
      return false;
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
      final EcoEvent? fresh = json == null ? null : ecoEventFromJson(json);
      if (fresh != null) {
        _replaceById(eventId, fresh);
        notifyListeners();
      }
      await _persistEventsDisk();
      return true;
    } on AppError {
      _events = previous;
      notifyListeners();
      rethrow;
    } on Object catch (e, st) {
      _events = previous;
      notifyListeners();
      Error.throwWithStackTrace(AppError.unknown(cause: e), st);
    } finally {
      _mutationsInFlight.remove('setReminder:$eventId');
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
    final List<String> normalized = LinkedHashSet<String>.from(
      imagePaths,
    ).toList(growable: false);
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
        await _client.postMultipart(
          '/events/$eventId/after-images',
          pathsForUpload,
        );
      }
      final ApiResponse refreshed = await _client.get('/events/$eventId');
      final Map<String, dynamic>? json = refreshed.json;
      final EcoEvent? fresh = json == null ? null : ecoEventFromJson(json);
      if (fresh != null) {
        _replaceById(eventId, fresh);
        notifyListeners();
      }
      await _persistEventsDisk();
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
  Future<EventImpactReceipt> fetchImpactReceipt(String eventId) async {
    final ApiResponse res = await _client.get(
      '/events/$eventId/impact-receipt',
    );
    final Map<String, dynamic>? json = res.json;
    if (json == null) {
      throw const AppError(code: 'SERVER_ERROR', message: '', retryable: false);
    }
    return eventImpactReceiptFromJson(json);
  }

  @override
  Future<bool> pushLiveImpactBags(
    String eventId,
    int reportedBagsCollected,
  ) async {
    final ApiResponse res = await _client.patch(
      '/events/$eventId/live-impact',
      body: <String, dynamic>{'reportedBagsCollected': reportedBagsCollected},
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}

bool _isHttpOrHttpsUrl(String raw) {
  final String t = raw.trim().toLowerCase();
  return t.startsWith('http://') || t.startsWith('https://');
}
