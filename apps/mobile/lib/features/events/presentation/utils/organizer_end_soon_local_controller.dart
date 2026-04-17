import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_service.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Schedules a single local notification at [event.endDateTime] − 10 minutes for
/// the organizer while a cleanup is [EcoEventStatus.inProgress].
class OrganizerEndSoonLocalController {
  String? _fingerprint;

  Future<void> sync({
    required EcoEvent? event,
    required PushNotificationService push,
    required AppLocalizations l10n,
  }) async {
    if (event == null ||
        !event.isOrganizer ||
        event.status != EcoEventStatus.inProgress) {
      await _cancelTracked(push);
      return;
    }
    final DateTime fireAt = event.endDateTime.subtract(const Duration(minutes: 10));
    if (!fireAt.isAfter(DateTime.now())) {
      await _cancelTracked(push);
      return;
    }
    final String nextFingerprint =
        '${event.id}|${event.endDateTime.toIso8601String()}|${event.status.name}';
    if (_fingerprint == nextFingerprint) {
      return;
    }
    await push.cancelOrganizerCleanupEndingSoon(event.id);
    await push.scheduleOrganizerCleanupEndingSoon(
      eventId: event.id,
      fireAtUtc: fireAt.toUtc(),
      title: l10n.eventsOrganizerEndSoonNotifyTitle,
      body: l10n.eventsOrganizerEndSoonNotifyBody,
      channelName: l10n.eventsOrganizerEndSoonNotifyChannelName,
      channelDescription: l10n.eventsOrganizerEndSoonNotifyChannelDescription,
    );
    _fingerprint = nextFingerprint;
  }

  Future<void> dispose(PushNotificationService push) async {
    await _cancelTracked(push);
  }

  Future<void> _cancelTracked(PushNotificationService push) async {
    final String? fp = _fingerprint;
    _fingerprint = null;
    if (fp == null) {
      return;
    }
    final String eventId = fp.split('|').first;
    await push.cancelOrganizerCleanupEndingSoon(eventId);
  }
}
