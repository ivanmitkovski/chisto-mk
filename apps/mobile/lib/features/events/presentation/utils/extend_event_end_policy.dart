import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

/// Mirrors [PUBLIC_EVENT_MAX_END_AFTER_START_MS] on the API (`PATCH /events/:id`).
const Duration kPublicEventMaxEndAfterStart = Duration(hours: 16);

/// Latest allowed local end instant for [event] (start + policy span).
DateTime maxAllowedEndLocal(EcoEvent event) {
  return event.startDateTime.add(kPublicEventMaxEndAfterStart);
}

/// Last minute of the event’s calendar [EcoEvent.date] (same-day UX cap).
DateTime endOfEventCalendarDay(EcoEvent event) {
  final DateTime d = event.date;
  return DateTime(d.year, d.month, d.day, 23, 59);
}

/// Caps [candidate] to API policy and same calendar day as the event start.
DateTime clampProposedEndLocal({
  required EcoEvent event,
  required DateTime candidate,
}) {
  final DateTime policyCap = maxAllowedEndLocal(event);
  final DateTime dayCap = endOfEventCalendarDay(event);
  DateTime capped = candidate.isBefore(policyCap) ? candidate : policyCap;
  if (capped.isAfter(dayCap)) {
    capped = dayCap;
  }
  final DateTime start = event.startDateTime;
  if (!capped.isAfter(start)) {
    capped = start.add(const Duration(minutes: 1));
  }
  return capped;
}

/// True when [proposedEndLocal] is a valid in-progress end (after start, same-day range, policy).
bool isProposedEndWithinPolicy({
  required EcoEvent event,
  required DateTime proposedEndLocal,
}) {
  final DateTime clamped = clampProposedEndLocal(
    event: event,
    candidate: proposedEndLocal,
  );
  return clamped.year == proposedEndLocal.year &&
      clamped.month == proposedEndLocal.month &&
      clamped.day == proposedEndLocal.day &&
      clamped.hour == proposedEndLocal.hour &&
      clamped.minute == proposedEndLocal.minute;
}
