import 'dart:async';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/check_in_redeem_queue_policy.dart';
import 'package:chisto_mobile/features/events/data/check_in_sync_queue.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';

/// POSTs a queued offline redeem; removes the queue entry on success or terminal errors.
Future<void> redeemOfflineCheckInEntry({
  required ApiClient client,
  required EventsRepository eventsRepository,
  required CheckInQueueEntry entry,
}) async {
  try {
    final ApiResponse response = await client.post(
      '/events/${entry.eventId}/check-in/redeem',
      body: <String, dynamic>{'qrPayload': entry.qrPayload},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await CheckInSyncQueue.instance.remove(entry.qrPayload);
      unawaited(eventsRepository.prefetchEvent(entry.eventId, force: true));
    }
  } on AppError catch (e) {
    if (shouldRemoveQueuedCheckInAfterRedeemError(e)) {
      await CheckInSyncQueue.instance.remove(entry.qrPayload);
      return;
    }
    rethrow;
  }
}
