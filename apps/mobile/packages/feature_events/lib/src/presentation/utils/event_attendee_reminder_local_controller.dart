import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_notifications/feature_notifications.dart';

/// Schedules a single OS-level local notification at [EcoEvent.reminderAt] for
/// joined attendees who enabled reminders via PATCH `/events/:id/reminder`.
class EventAttendeeReminderLocalController {
  String? _fingerprint;

  Future<void> sync({
    required EcoEvent? event,
    required PushNotificationService push,
    required AppLocalizations l10n,
  }) async {
    if (event == null ||
        !event.isJoined ||
        !event.reminderEnabled ||
        event.reminderAt == null) {
      await _cancelTracked(push, eventId: event?.id);
      return;
    }
    final DateTime fireAt = event.reminderAt!;
    if (!fireAt.isAfter(DateTime.now())) {
      await _cancelTracked(push, eventId: event.id);
      return;
    }
    final String nextFingerprint =
        '${event.id}|${fireAt.toIso8601String()}|${event.title}';
    if (_fingerprint == nextFingerprint) {
      return;
    }
    await push.cancelEventAttendeeReminder(event.id);
    await push.scheduleEventAttendeeReminder(
      eventId: event.id,
      fireAtUtc: fireAt.toUtc(),
      title: l10n.eventsAttendeeReminderNotifyTitle,
      body: l10n.eventsAttendeeReminderNotifyBody(event.title),
      channelName: l10n.pushChannelEventsName,
      channelDescription: l10n.pushChannelEventsDescription,
    );
    _fingerprint = nextFingerprint;
  }

  Future<void> dispose(PushNotificationService push) async {
    await _cancelTracked(push, eventId: null);
  }

  Future<void> _cancelTracked(
    PushNotificationService push, {
    required String? eventId,
  }) async {
    final String? fp = _fingerprint;
    _fingerprint = null;
    final String? id = eventId ?? fp?.split('|').first;
    if (id == null || id.isEmpty) {
      return;
    }
    await push.cancelEventAttendeeReminder(id);
  }
}
