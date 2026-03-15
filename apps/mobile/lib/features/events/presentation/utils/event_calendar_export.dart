import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

class EventCalendarExport {
  EventCalendarExport._();

  static Future<void> addToCalendar(EcoEvent event) async {
    final Event calEvent = Event(
      title: event.title,
      description: event.description.isEmpty ? null : event.description,
      location: event.siteName.isEmpty ? null : event.siteName,
      startDate: event.startDateTime,
      endDate: event.endDateTime,
    );
    await Add2Calendar.addEvent2Cal(calEvent);
  }
}
