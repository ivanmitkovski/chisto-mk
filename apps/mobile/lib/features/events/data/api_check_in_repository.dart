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
import 'package:geolocator/geolocator.dart';
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
      final Map<String, dynamic> body = <String, dynamic>{
        'qrPayload': rawPayload.trim(),
      };
      try {
        final Position? last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          body['redeemLatitude'] = last.latitude;
          body['redeemLongitude'] = last.longitude;
        }
      } on Object {
        // Optional geo for risk scoring — ignore all failures.
      }
      final ApiResponse response = await _client.post(
        '/events/$expectedEventId/check-in/redeem',
        body: body,
      );
      final Map<String, dynamic>? json = response.json;

      final String? responseStatus = json?['status'] as String?;

      if (responseStatus == 'pending_confirmation') {
        final String? pendingId = json?['pendingId'] as String?;
        final String? expiresAtIso = json?['expiresAt'] as String?;
        final DateTime? expiresAt = expiresAtIso != null
            ? DateTime.tryParse(expiresAtIso)?.toLocal()
            : null;
        return CheckInSubmissionResult(
          status: CheckInSubmissionStatus.pendingConfirmation,
          pendingId: pendingId,
          pendingExpiresAt: expiresAt,
        );
      }

      if (responseStatus == 'already_checked_in') {
        final DateTime? at = _redeemResponseCheckedInAt(json);
        _events.setAttendeeCheckInStatus(
          eventId: expectedEventId,
          status: AttendeeCheckInStatus.checkedIn,
          checkedInAt: at ?? DateTime.now(),
        );
        return CheckInSubmissionResult(
          status: CheckInSubmissionStatus.alreadyCheckedIn,
          checkedInAt: at,
          pointsAwarded: 0,
        );
      }

      // Legacy direct-check-in path (should not happen with new API).
      final DateTime? at = _redeemResponseCheckedInAt(json);
      if (at == null) {
        return const CheckInSubmissionResult(
          status: CheckInSubmissionStatus.invalidFormat,
        );
      }
      final int pointsAwarded = parsePointsAwardedFromJson(json);
      final CheckInSubmissionResult result = CheckInSubmissionResult(
        status: CheckInSubmissionStatus.success,
        checkedInAt: at,
        pointsAwarded: pointsAwarded,
      );
      _events.setAttendeeCheckInStatus(
        eventId: expectedEventId,
        status: AttendeeCheckInStatus.checkedIn,
        checkedInAt: at,
      );
      try {
        await refreshAttendees(expectedEventId);
      } on Object {
        // List may lag until organizer polling.
      }
      unawaited(_events.prefetchEvent(expectedEventId, force: true));
      return result;
    } on SocketException {
      await _enqueueOfflineAndSetOptimistic(expectedEventId, rawPayload);
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.queuedOffline,
      );
    } on TimeoutException {
      await _enqueueOfflineAndSetOptimistic(expectedEventId, rawPayload);
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.queuedOffline,
      );
    } on AppError catch (e) {
      if (_isQueuedOfflineTransportError(e)) {
        await _enqueueOfflineAndSetOptimistic(expectedEventId, rawPayload);
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

  Future<void> _enqueueOfflineAndSetOptimistic(
    String eventId,
    String rawPayload,
  ) async {
    await CheckInSyncQueue.instance.enqueue(
      CheckInQueueEntry(
        eventId: eventId,
        qrPayload: rawPayload.trim(),
        enqueuedAt: DateTime.now(),
      ),
    );
    _events.setAttendeeCheckInStatus(
      eventId: eventId,
      status: AttendeeCheckInStatus.checkedIn,
      checkedInAt: DateTime.now(),
    );
  }

  bool _isQueuedOfflineTransportError(AppError e) {
    switch (e.code) {
      case 'NETWORK_ERROR':
      case 'TIMEOUT':
      case 'no_internet':
      case 'network':
        return true;
      default:
        return false;
    }
  }

  CheckInSubmissionStatus _statusForAppError(AppError e) {
    switch (e.code) {
      case 'CHECK_IN_WRONG_EVENT':
        return CheckInSubmissionStatus.wrongEvent;
      case 'CHECK_IN_SESSION_CLOSED':
      case 'CHECK_IN_NO_SESSION':
        return CheckInSubmissionStatus.sessionClosed;
      case 'CHECK_IN_QR_EXPIRED':
      case 'CHECK_IN_SESSION_MISMATCH':
      case 'CHECK_IN_REQUEST_EXPIRED':
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
      case 'CHECK_IN_REQUEST_NOT_FOUND':
      case 'CHECK_IN_FORBIDDEN':
      case 'CHECK_IN_MISCONFIG':
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
    await _client.patch(
      '/events/$eventId/check-in',
      body: <String, dynamic>{'isOpen': false},
    );
    _events.setCheckInOpen(eventId: eventId, isOpen: false);
    unawaited(_events.prefetchEvent(eventId, force: true));
    return true;
  }

  @override
  Future<bool> resumeSession(String eventId) async {
    await _client.patch(
      '/events/$eventId/check-in',
      body: <String, dynamic>{'isOpen': true},
    );
    _events.setCheckInOpen(eventId: eventId, isOpen: true);
    unawaited(_events.prefetchEvent(eventId, force: true));
    return true;
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
  Future<void> resolvePendingCheckIn({
    required String eventId,
    required String pendingId,
    required bool approve,
  }) async {
    await _client.post(
      '/events/$eventId/check-in/pending/$pendingId/resolve',
      body: <String, dynamic>{
        'action': approve ? 'approve' : 'reject',
      },
    );
    if (approve) {
      try {
        await refreshAttendees(eventId);
      } on Object {
        // Will be picked up by the next poll.
      }
      unawaited(_events.prefetchEvent(eventId, force: true));
    }
  }

  @override
  Future<String?> pollPendingStatus({
    required String eventId,
    required String pendingId,
  }) async {
    try {
      final ApiResponse response = await _client.get(
        '/events/$eventId/check-in/pending/$pendingId',
      );
      final Map<String, dynamic>? json = response.json;
      return json?['status'] as String?;
    } on Object {
      return null;
    }
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
