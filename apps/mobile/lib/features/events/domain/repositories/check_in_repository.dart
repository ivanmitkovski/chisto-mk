import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:flutter/foundation.dart';

abstract class CheckInRepository implements Listenable {
  Duration get payloadTtl;

  String ensureSession({
    required EcoEvent event,
    bool openIfNeeded = true,
  });

  CheckInQrPayload issuePayload({
    required String eventId,
  });

  CheckInSubmissionResult submitScan({
    required String rawPayload,
    required String expectedEventId,
    required String attendeeId,
    required String attendeeName,
  });

  bool markAttendeeCheckedIn({
    required String eventId,
    required String attendeeId,
    required String attendeeName,
  });

  bool removeCheckedInAttendee({
    required String eventId,
    required String attendeeId,
  });

  bool pauseSession(String eventId);
  bool resumeSession(String eventId);
  bool closeSession(String eventId);

  List<CheckedInAttendee> checkedInAttendees(String eventId);
  int checkedInCount(String eventId);
  bool isOpen(String eventId);
}
