import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:feature_events/src/data/event_calendar_added_store.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/utils/event_calendar_add_result.dart';

class EventCalendarExport {
  EventCalendarExport._();

  /// Whether this device has recorded a successful add for [event] (same schedule).
  static Future<bool> isAddedToCalendar(EcoEvent event) {
    return EventCalendarAddedStore.isMarkedAdded(event);
  }

  /// Opens the native calendar UI to add [event], or reports already-added state.
  static Future<EventCalendarAddResult> requestAdd(EcoEvent event) async {
    if (await EventCalendarAddedStore.isMarkedAdded(event)) {
      return EventCalendarAddResult.alreadyAdded;
    }

    try {
      final Event calEvent = Event(
        title: event.title,
        description: event.description.isEmpty ? null : event.description,
        location: event.siteName.isEmpty ? null : event.siteName,
        startDate: event.startDateTime,
        endDate: event.endDateTime,
      );
      final bool launched = await Add2Calendar.addEvent2Cal(calEvent);
      if (!launched) {
        AppLog.verbose(
          '[EventCalendarExport] addEvent2Cal returned false eventId=${event.id}',
        );
        return EventCalendarAddResult.cancelled;
      }
      await EventCalendarAddedStore.markAdded(event);
      return EventCalendarAddResult.added;
    } on Object catch (e, st) {
      AppLog.warn(
        '[EventCalendarExport] add failed eventId=${event.id}',
        error: e,
        stackTrace: st,
      );
      return EventCalendarAddResult.failed;
    }
  }
}
