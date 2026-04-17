import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:flutter/foundation.dart';

abstract class CheckInRepository implements Listenable {
  Duration get payloadTtl;

  /// Dev-only organizer “simulate scan” uses local fake attendees; API mode has no equivalent.
  bool get supportsOrganizerSimulate;

  /// Refetch attendee list from the server (no-op for in-memory dev repo).
  Future<void> refreshAttendees(String eventId);

  Future<String> ensureSession({
    required EcoEvent event,
    bool openIfNeeded = true,
  });

  Future<CheckInQrPayload> issuePayload({
    required String eventId,
  });

  Future<CheckInSubmissionResult> submitScan({
    required String rawPayload,
    required String expectedEventId,
    required String attendeeId,
    required String attendeeName,
  });

  Future<ManualCheckInResult> markAttendeeCheckedIn({
    required String eventId,
    required String attendeeId,
    required String attendeeName,
  });

  Future<bool> removeCheckedInAttendee({
    required String eventId,
    required String attendeeId,
  });

  Future<bool> pauseSession(String eventId);
  Future<bool> resumeSession(String eventId);
  Future<bool> closeSession(String eventId);

  /// Server: `POST /events/:id/check-in/session/rotate`. No-op for in-memory when not implemented.
  Future<void> rotateSession(String eventId);

  /// Organizer approves or rejects a pending QR check-in request.
  Future<void> resolvePendingCheckIn({
    required String eventId,
    required String pendingId,
    required bool approve,
  });

  /// Volunteer fallback poll for pending check-in status.
  /// Returns `'pending'`, `'expired'`, or `null` on network failure.
  Future<String?> pollPendingStatus({
    required String eventId,
    required String pendingId,
  });

  List<CheckedInAttendee> checkedInAttendees(String eventId);
  int checkedInCount(String eventId);
  bool isOpen(String eventId);
}
