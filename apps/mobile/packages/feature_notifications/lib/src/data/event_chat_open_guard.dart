import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_events/feature_events.dart';

/// Preflight for opening event chat from notifications.
class EventChatOpenGuard {
  const EventChatOpenGuard._();

  /// True when the event is cached or successfully prefetched.
  ///
  /// Returns true on transient/network [AppError] so the chat screen can retry.
  static Future<bool> isEventAvailableForChat(String eventId) async {
    final String id = eventId.trim();
    if (id.isEmpty) {
      return false;
    }

    final EventsRepository repo = readEventsRepository();
    if (repo.findById(id) != null) {
      return true;
    }

    try {
      await repo.prefetchEvent(id);
    } on AppError {
      return true;
    }

    return repo.findById(id) != null;
  }
}
