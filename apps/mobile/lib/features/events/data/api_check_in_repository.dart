import 'dart:async';
import 'dart:io';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/check_in_sync_queue.dart';
import 'package:chisto_mobile/features/events/data/event_json.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:flutter/foundation.dart';

/// Parses `checkedInAt` from POST `/events/:id/check-in/redeem` success JSON (root or `data`).
DateTime? _redeemResponseCheckedInAt(Map<String, dynamic>? json) {
  if (json == null) {
    return null;
  }
  String? iso;
  final Object? top = json['checkedInAt'];
  if (top is String && top.isNotEmpty) {
    iso = top;
  } else {
    final Object? data = json['data'];
    if (data is Map<String, dynamic>) {
      final Object? inner = data['checkedInAt'];
      if (inner is String && inner.isNotEmpty) {
        iso = inner;
      }
    }
  }
  if (iso == null) {
    return null;
  }
  final DateTime? parsed = DateTime.tryParse(iso);
  return parsed?.toLocal();
}

/// Server-backed check-in: signed QR from GET `/events/:id/check-in/qr`, redeem via POST.
class ApiCheckInRepository extends ChangeNotifier implements CheckInRepository {
  ApiCheckInRepository({
    required ApiClient client,
    required EventsRepository eventsRepository,
  })  : _client = client,
        _events = eventsRepository;

  static const int _qrTtlSec = 60;

  final ApiClient _client;
  final EventsRepository _events;

  final Map<String, List<CheckedInAttendee>> _attendeesByEvent =
      <String, List<CheckedInAttendee>>{};

  @override
  Duration get payloadTtl =>
      const Duration(seconds: _qrTtlSec - 10);

  @override
  bool get supportsOrganizerSimulate => false;

  @override
  Future<void> refreshAttendees(String eventId) async {
    final String id = eventId.trim();
    if (id.isEmpty) {
      return;
    }
    try {
      final ApiResponse response = await _client.get('/events/$id/check-in/attendees');
      final Map<String, dynamic>? json = response.json;
      final List<dynamic>? raw = json?['data'] as List<dynamic>?;
      if (raw == null) {
        return;
      }
      final List<CheckedInAttendee> next = raw
          .whereType<Map<String, dynamic>>()
          .map(CheckedInAttendee.fromApiJson)
          .whereType<CheckedInAttendee>()
          .toList(growable: false);
      _attendeesByEvent[id] = next;
      notifyListeners();
    } on Object {
      rethrow;
    }
  }

  @override
  Future<String> ensureSession({
    required EcoEvent event,
    bool openIfNeeded = true,
  }) async {
    if (openIfNeeded) {
      await _client.patch(
        '/events/${event.id}/check-in',
        body: <String, dynamic>{'isOpen': true},
      );
      _events.setCheckInOpen(eventId: event.id, isOpen: true);
    }
    unawaited(_events.prefetchEvent(event.id, force: true));
    return _events.findById(event.id)?.activeCheckInSessionId ?? '';
  }

  @override
  Future<CheckInQrPayload> issuePayload({required String eventId}) async {
    final ApiResponse response =
        await _client.get('/events/$eventId/check-in/qr');
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    final CheckInQrPayload? payload =
        CheckInQrPayload.fromOrganizerQrApiJson(json);
    if (payload == null) {
      throw AppError.unknown();
    }
    return payload;
  }

  @override
  Future<CheckInSubmissionResult> submitScan({
    required String rawPayload,
    required String expectedEventId,
    required String attendeeId,
    required String attendeeName,
  }) async {
    if (attendeeId.isEmpty || attendeeName.isEmpty) {
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.invalidFormat,
      );
    }
    try {
      final ApiResponse response = await _client.post(
        '/events/$expectedEventId/check-in/redeem',
        body: <String, dynamic>{'qrPayload': rawPayload.trim()},
      );
      final Map<String, dynamic>? json = response.json;
      final DateTime? at = _redeemResponseCheckedInAt(json);
      if (at == null) {
        return const CheckInSubmissionResult(
          status: CheckInSubmissionStatus.invalidFormat,
        );
      }
      final int pointsAwarded = parsePointsAwardedFromJson(json);
      await _events.prefetchEvent(expectedEventId, force: true);
      await refreshAttendees(expectedEventId);
      return CheckInSubmissionResult(
        status: CheckInSubmissionStatus.success,
        checkedInAt: at,
        pointsAwarded: pointsAwarded,
      );
    } on SocketException {
      // No network — queue for offline sync and show optimistic success.
      await CheckInSyncQueue.instance.enqueue(
        CheckInQueueEntry(
          eventId: expectedEventId,
          qrPayload: rawPayload.trim(),
          enqueuedAt: DateTime.now(),
        ),
      );
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.queuedOffline,
      );
    } on AppError catch (e) {
      if (e.code == 'no_internet' || e.code == 'network') {
        await CheckInSyncQueue.instance.enqueue(
          CheckInQueueEntry(
            eventId: expectedEventId,
            qrPayload: rawPayload.trim(),
            enqueuedAt: DateTime.now(),
          ),
        );
        return const CheckInSubmissionResult(
          status: CheckInSubmissionStatus.queuedOffline,
        );
      }
      return CheckInSubmissionResult(
        status: _statusForAppError(e),
        checkedInAt: null,
      );
    }
  }

  @visibleForTesting
  CheckInSubmissionStatus submissionStatusForAppError(AppError e) =>
      _statusForAppError(e);

  CheckInSubmissionStatus _statusForAppError(AppError e) {
    switch (e.code) {
      case 'CHECK_IN_WRONG_EVENT':
        return CheckInSubmissionStatus.wrongEvent;
      case 'CHECK_IN_SESSION_CLOSED':
      case 'CHECK_IN_NO_SESSION':
        return CheckInSubmissionStatus.sessionClosed;
      case 'CHECK_IN_QR_EXPIRED':
      case 'CHECK_IN_SESSION_MISMATCH':
        return CheckInSubmissionStatus.sessionExpired;
      case 'CHECK_IN_REPLAY':
        return CheckInSubmissionStatus.replayDetected;
      case 'CONFLICT':
        // Fallback when the body omits a string `code` but HTTP 409 is still a redeem conflict.
        return CheckInSubmissionStatus.replayDetected;
      case 'CHECK_IN_ALREADY_CHECKED_IN':
        return CheckInSubmissionStatus.alreadyCheckedIn;
      case 'CHECK_IN_REQUIRES_JOIN':
        return CheckInSubmissionStatus.requiresJoin;
      case 'CHECK_IN_INVALID_QR':
        return CheckInSubmissionStatus.invalidQr;
      case 'ORGANIZER_CANNOT_CHECK_IN':
      case 'EVENT_NOT_JOINABLE':
      case 'CHECK_IN_LIFECYCLE':
      case 'EVENT_NOT_FOUND':
      case 'CHECK_IN_NOT_FOUND':
        return CheckInSubmissionStatus.checkInUnavailable;
      case 'TOO_MANY_REQUESTS':
        return CheckInSubmissionStatus.rateLimited;
      default:
        return CheckInSubmissionStatus.invalidFormat;
    }
  }

  @override
  Future<ManualCheckInResult> markAttendeeCheckedIn({
    required String eventId,
    required String attendeeId,
    required String attendeeName,
  }) async {
    try {
      final ApiResponse response = await _client.post(
        '/events/$eventId/check-in/manual',
        body: <String, dynamic>{'userId': attendeeId.trim()},
      );
      final int pointsAwarded = parsePointsAwardedFromJson(response.json);
      await refreshAttendees(eventId);
      await _events.prefetchEvent(eventId, force: true);
      return ManualCheckInResult(recorded: true, pointsAwarded: pointsAwarded);
    } on AppError catch (e) {
      if (e.code == 'CHECK_IN_ALREADY_RECORDED') {
        return const ManualCheckInResult(recorded: false);
      }
      rethrow;
    }
  }

  @override
  Future<bool> removeCheckedInAttendee({
    required String eventId,
    required String attendeeId,
  }) async {
    try {
      await _client.delete('/events/$eventId/check-in/attendees/$attendeeId');
      await refreshAttendees(eventId);
      await _events.prefetchEvent(eventId, force: true);
      return true;
    } on AppError catch (e) {
      if (e.code == 'NOT_FOUND' || e.code == 'CHECK_IN_NOT_FOUND') {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> pauseSession(String eventId) async {
    try {
      await _client.patch(
        '/events/$eventId/check-in',
        body: <String, dynamic>{'isOpen': false},
      );
      // [prefetchEvent] skips the network when the event is already cached, so
      // the PATCH would not be reflected in [EcoEvent.isCheckInOpen] without this.
      _events.setCheckInOpen(eventId: eventId, isOpen: false);
      unawaited(_events.prefetchEvent(eventId, force: true));
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> resumeSession(String eventId) async {
    try {
      await _client.patch(
        '/events/$eventId/check-in',
        body: <String, dynamic>{'isOpen': true},
      );
      _events.setCheckInOpen(eventId: eventId, isOpen: true);
      unawaited(_events.prefetchEvent(eventId, force: true));
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> closeSession(String eventId) async {
    return pauseSession(eventId);
  }

  @override
  Future<void> rotateSession(String eventId) async {
    final String id = eventId.trim();
    if (id.isEmpty) {
      return;
    }
    await _client.post(
      '/events/$id/check-in/session/rotate',
      body: <String, dynamic>{},
    );
    await _events.prefetchEvent(id, force: true);
  }

  @override
  List<CheckedInAttendee> checkedInAttendees(String eventId) {
    return List<CheckedInAttendee>.unmodifiable(
      _attendeesByEvent[eventId] ?? const <CheckedInAttendee>[],
    );
  }

  @override
  int checkedInCount(String eventId) {
    final EcoEvent? e = _events.findById(eventId);
    return e?.checkedInCount ?? checkedInAttendees(eventId).length;
  }

  @override
  bool isOpen(String eventId) {
    return _events.findById(eventId)?.isCheckInOpen ?? false;
  }
}
