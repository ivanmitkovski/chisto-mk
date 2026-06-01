part of 'api_events_repository.dart';

mixin ApiEventsRepositoryMutations on _ApiEventsRepositoryBase {
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
    final ApiResponse response = await _client.patch(
      '/events/$eventId',
      body: body,
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    final EcoEvent? updated = ecoEventFromJson(json);
    if (updated == null) throw AppError.unknown();
    _replaceById(eventId, updated);
    notifyListeners();
    await _persistEventsDisk();
    return updated;
  }

  @override
  void resetToSeed() => super.resetToSeed();

  @override
  EcoEvent? findById(String id) => super.findById(id);

  @override
  EcoEvent? findBySiteAndTitle({
    required String siteId,
    required String title,
  }) => super.findBySiteAndTitle(siteId: siteId, title: title);

  Map<String, dynamic> _createBody(EcoEvent event) {
    return <String, dynamic>{
      'siteId': event.siteId,
      'title': event.title,
      'description': event.description,
      'category': event.category.name,
      'scheduledAt': event.startDateTime.toUtc().toIso8601String(),
      'endAt': event.endDateTime.toUtc().toIso8601String(),
      if (event.maxParticipants != null)
        'maxParticipants': event.maxParticipants,
      'gear': event.gear.map((EventGear g) => g.name).toList(growable: false),
      if (event.scale != null) 'scale': event.scale!.name,
      if (event.difficulty != null) 'difficulty': event.difficulty!.name,
    };
  }

  @override
  Future<EventScheduleConflictPreview> checkScheduleConflict({
    required String siteId,
    required DateTime scheduledAt,
    DateTime? endAt,
    String? excludeEventId,
  }) async {
    final Map<String, String> query = <String, String>{
      'siteId': siteId,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
    };
    if (endAt != null) {
      query['endAt'] = endAt.toUtc().toIso8601String();
    }
    if (excludeEventId != null && excludeEventId.isNotEmpty) {
      query['excludeEventId'] = excludeEventId;
    }
    final String qs = Uri(queryParameters: query).query;
    final ApiResponse response = await _client.get(
      '/events/check-conflict?$qs',
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    final bool hasConflict = json['hasConflict'] == true;
    final ConflictingEventInfo? conflicting = conflictingEventFromNestedJson(
      json['conflictingEvent'],
    );
    return EventScheduleConflictPreview(
      hasConflict: hasConflict,
      conflictingEvent: conflicting,
    );
  }

  @override
  Future<EcoEvent> create(EcoEvent event) async {
    final ApiResponse response = await _client.post(
      '/events',
      body: _createBody(event),
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    final EcoEvent? created = ecoEventFromJson(json);
    if (created == null) throw AppError.unknown();
    _upsert(created);
    notifyListeners();
    await _persistEventsDisk();
    return created;
  }

  @override
  Future<bool> updateStatus(String id, EcoEventStatus status) async {
    final EcoEvent? current = findById(id);
    if (current == null || !current.canTransitionTo(status)) {
      return false;
    }
    if (!_mutationsInFlight.add('updateStatus:$id')) {
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
      final EcoEvent? fresh = json == null ? null : ecoEventFromJson(json);
      if (fresh != null) {
        _replaceById(id, fresh);
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
      _mutationsInFlight.remove('updateStatus:$id');
    }
  }

  @override
  Future<EcoEventJoinToggleResult> toggleJoin(String id) async {
    final EcoEvent? event = findById(id);
    if (event == null || !event.isJoinable) {
      return const EcoEventJoinToggleResult(changed: false);
    }
    if (!event.isJoined && !event.canVolunteerJoinNow) {
      return const EcoEventJoinToggleResult(changed: false);
    }
    if (!event.isJoined &&
        event.maxParticipants != null &&
        event.participantCount >= event.maxParticipants!) {
      return const EcoEventJoinToggleResult(changed: false);
    }
    if (!_mutationsInFlight.add('toggleJoin:$id')) {
      return const EcoEventJoinToggleResult(changed: false);
    }

    final List<EcoEvent> previous = List<EcoEvent>.from(_events);
    final bool nextJoined = !event.isJoined;
    final int nextCount = nextJoined
        ? event.participantCount + 1
        : (event.participantCount - 1).clamp(0, 1000000);
    _replaceById(
      id,
      event.copyWith(isJoined: nextJoined, participantCount: nextCount),
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
      final EcoEvent? fresh = json == null ? null : ecoEventFromJson(json);
      if (fresh != null) {
        _replaceById(id, fresh);
        notifyListeners();
      }
      await _persistEventsDisk();
      return EcoEventJoinToggleResult(
        changed: true,
        pointsAwarded: pointsAwarded,
      );
    } on AppError {
      _events = previous;
      notifyListeners();
      rethrow;
    } on Object catch (e, st) {
      _events = previous;
      notifyListeners();
      Error.throwWithStackTrace(AppError.unknown(cause: e), st);
    } finally {
      _mutationsInFlight.remove('toggleJoin:$id');
    }
  }
}
