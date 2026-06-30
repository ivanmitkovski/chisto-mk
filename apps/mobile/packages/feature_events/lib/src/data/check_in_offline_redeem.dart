import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:feature_events/src/data/check_in_redeem_queue_policy.dart';
import 'package:feature_events/src/data/check_in_redeem_response.dart';
import 'package:feature_events/src/data/check_in_sync_queue.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/repositories/check_in_repository.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';

void _revertLocalCheckIn(EventsRepository eventsRepository, String eventId) {
  eventsRepository.setAttendeeCheckInStatus(
    eventId: eventId,
    status: AttendeeCheckInStatus.notCheckedIn,
    checkedInAt: null,
  );
}

void _applyRedeemSuccessToLocalState({
  required EventsRepository eventsRepository,
  required String eventId,
  required Map<String, dynamic>? json,
}) {
  if (redeemResponseIsPendingConfirmation(json)) {
    _revertLocalCheckIn(eventsRepository, eventId);
    return;
  }
  final DateTime? at = redeemResponseCheckedInAt(json);
  if (at == null) {
    _revertLocalCheckIn(eventsRepository, eventId);
    return;
  }
  eventsRepository.setAttendeeCheckInStatus(
    eventId: eventId,
    status: AttendeeCheckInStatus.checkedIn,
    checkedInAt: at,
  );
}

/// POSTs a queued offline redeem; removes the queue entry on success or terminal errors.
Future<void> redeemOfflineCheckInEntry({
  required ApiClient client,
  required EventsRepository eventsRepository,
  required CheckInQueueEntry entry,
  CheckInRepository? checkInRepository,
}) async {
  try {
    final ApiResponse response = await client.post(
      '/events/${entry.eventId}/check-in/redeem',
      body: <String, dynamic>{'qrPayload': entry.qrPayload},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await CheckInSyncQueue.instance.remove(entry.qrPayload);
      _applyRedeemSuccessToLocalState(
        eventsRepository: eventsRepository,
        eventId: entry.eventId,
        json: response.json,
      );
      unawaited(eventsRepository.prefetchEvent(entry.eventId, force: true));
      if (checkInRepository != null) {
        unawaited(checkInRepository.refreshAttendees(entry.eventId));
      }
    }
  } on AppError catch (e) {
    if (shouldRemoveQueuedCheckInAfterRedeemError(e)) {
      await CheckInSyncQueue.instance.remove(entry.qrPayload);
      _revertLocalCheckIn(eventsRepository, entry.eventId);
      return;
    }
    rethrow;
  }
}
