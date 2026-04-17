import 'package:flutter/material.dart';

import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

// Same-calendar-day start/end only; overnight or multi-day spans are out of scope here.

/// Minimum lead time before scheduled start for new events and upcoming edits.
const Duration kEventScheduleMinLead = Duration(minutes: 5);

/// Snap picker and clamped times to this grid (minutes).
const int kEventScheduleTimeGridMinutes = 5;

/// Local wall-clock instant for [dateOnly] + [time] (same convention as [EcoEvent.startDateTime]).
DateTime eventScheduleInstantLocal(DateTime dateOnly, EventTime time) {
  return DateTime(
    dateOnly.year,
    dateOnly.month,
    dateOnly.day,
    time.hour,
    time.minute,
  );
}

DateTime _pickerShell(int hour, int minute) =>
    DateTime(2000, 1, 1, hour.clamp(0, 23), minute.clamp(0, 59));

/// Rounds [dt] up to the next [stepMinutes] boundary (ceiling in local time).
DateTime ceilToMinuteGrid(DateTime dt, {int stepMinutes = kEventScheduleTimeGridMinutes}) {
  if (stepMinutes <= 0) {
    return dt;
  }
  final int total = dt.hour * 60 + dt.minute;
  final int rem = total % stepMinutes;
  if (rem == 0 && dt.second == 0 && dt.millisecond == 0 && dt.microsecond == 0) {
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }
  final int add = rem == 0 ? stepMinutes : (stepMinutes - rem);
  final DateTime bumped = dt.add(Duration(minutes: add));
  return DateTime(bumped.year, bumped.month, bumped.day, bumped.hour, bumped.minute);
}

EventTime eventTimeFromDateTime(DateTime dt) {
  return EventTime(hour: dt.hour, minute: dt.minute);
}

/// Why schedule validation failed (single primary reason for UX).
enum ScheduleValidationIssue {
  /// [EcoEvent.isValidRange] is false.
  endNotAfterStart,

  /// Start is before [earliestStartInstant] (e.g. now + lead on create/upcoming edit).
  startTooSoon,

  /// End is not after now + lead (in-progress edit).
  endTooSoon,
}

DateTime _earliestStartInstant(DateTime now, Duration minLead) {
  return ceilToMinuteGrid(now.add(minLead));
}

/// Validates create flow and edit while event is [EcoEventStatus.upcoming].
ScheduleValidationIssue? validateCreateOrUpcomingEditSchedule({
  required DateTime dateOnly,
  required EventTime start,
  required EventTime end,
  required DateTime now,
  Duration minLead = kEventScheduleMinLead,
}) {
  if (!EcoEvent.isValidRange(start, end)) {
    return ScheduleValidationIssue.endNotAfterStart;
  }
  final DateTime today = DateUtils.dateOnly(now);
  if (dateOnly.isBefore(today)) {
    return ScheduleValidationIssue.startTooSoon;
  }
  final DateTime startInstant = eventScheduleInstantLocal(dateOnly, start);
  final DateTime earliest = _earliestStartInstant(now, minLead);
  if (startInstant.isBefore(earliest)) {
    return ScheduleValidationIssue.startTooSoon;
  }
  return null;
}

/// Validates edit while event is in progress: start may be in the past; end must be after now + lead.
ScheduleValidationIssue? validateInProgressEditSchedule({
  required DateTime dateOnly,
  required EventTime start,
  required EventTime end,
  required DateTime now,
  Duration minLead = kEventScheduleMinLead,
}) {
  if (!EcoEvent.isValidRange(start, end)) {
    return ScheduleValidationIssue.endNotAfterStart;
  }
  final DateTime endInstant = eventScheduleInstantLocal(dateOnly, end);
  final DateTime earliestEnd = _earliestStartInstant(now, minLead);
  if (endInstant.isBefore(earliestEnd) || endInstant.isAtSameMomentAs(earliestEnd)) {
    return ScheduleValidationIssue.endTooSoon;
  }
  return null;
}

ScheduleValidationIssue? validateEditSchedule({
  required EcoEventStatus status,
  required DateTime dateOnly,
  required EventTime start,
  required EventTime end,
  required DateTime now,
  Duration minLead = kEventScheduleMinLead,
}) {
  switch (status) {
    case EcoEventStatus.upcoming:
      return validateCreateOrUpcomingEditSchedule(
        dateOnly: dateOnly,
        start: start,
        end: end,
        now: now,
        minLead: minLead,
      );
    case EcoEventStatus.inProgress:
      return validateInProgressEditSchedule(
        dateOnly: dateOnly,
        start: start,
        end: end,
        now: now,
        minLead: minLead,
      );
    case EcoEventStatus.completed:
    case EcoEventStatus.cancelled:
      return null;
  }
}

/// Picks default start/end for create when [dateOnly] is today: next grid slot + 2h duration.
({EventTime start, EventTime end}) defaultStartEndForDate({
  required DateTime dateOnly,
  required DateTime now,
  Duration minLead = kEventScheduleMinLead,
  int defaultDurationHours = 2,
}) {
  final DateTime today = DateUtils.dateOnly(now);
  if (dateOnly.isBefore(today)) {
    final EventTime s = eventTimeFromDateTime(
      ceilToMinuteGrid(DateTime(today.year, today.month, today.day, 9, 0)),
    );
    final DateTime endDt = DateTime(today.year, today.month, today.day, s.hour, s.minute)
        .add(Duration(hours: defaultDurationHours));
    return (start: s, end: eventTimeFromDateTime(endDt));
  }
  if (dateOnly.isAfter(today)) {
    const EventTime s = EventTime(hour: 10, minute: 0);
    const EventTime e = EventTime(hour: 12, minute: 0);
    return (start: s, end: e);
  }
  final DateTime startDt = ceilToMinuteGrid(now.add(minLead));
  final DateTime endDt = startDt.add(Duration(hours: defaultDurationHours));
  return (
    start: eventTimeFromDateTime(startDt),
    end: eventTimeFromDateTime(endDt),
  );
}

/// After date change or when current pair is invalid, snap to a valid pair for **create** / upcoming.
({EventTime start, EventTime end}) clampCreateOrUpcomingSchedule({
  required DateTime dateOnly,
  required EventTime start,
  required EventTime end,
  required DateTime now,
  Duration minLead = kEventScheduleMinLead,
  int defaultDurationHours = 2,
}) {
  final issue = validateCreateOrUpcomingEditSchedule(
    dateOnly: dateOnly,
    start: start,
    end: end,
    now: now,
    minLead: minLead,
  );
  if (issue == null) {
    return (start: start, end: end);
  }
  final ({EventTime start, EventTime end}) defaults = defaultStartEndForDate(
    dateOnly: dateOnly,
    now: now,
    minLead: minLead,
    defaultDurationHours: defaultDurationHours,
  );
  EventTime s = defaults.start;
  EventTime e = defaults.end;
  // If defaults somehow invalid (should not), widen end.
  if (!EcoEvent.isValidRange(s, e)) {
    final DateTime sdt = eventScheduleInstantLocal(dateOnly, s);
    e = eventTimeFromDateTime(sdt.add(Duration(hours: defaultDurationHours)));
  }
  return (start: s, end: e);
}

/// Clamp for in-progress edit: keep [start] if range invalid or end too soon; bump [end].
({EventTime start, EventTime end}) clampInProgressEditSchedule({
  required DateTime dateOnly,
  required EventTime start,
  required EventTime end,
  required DateTime now,
  Duration minLead = kEventScheduleMinLead,
  int defaultDurationHours = 2,
}) {
  if (validateInProgressEditSchedule(
        dateOnly: dateOnly,
        start: start,
        end: end,
        now: now,
        minLead: minLead,
      ) ==
      null) {
    return (start: start, end: end);
  }
  final DateTime earliestEnd = _earliestStartInstant(now, minLead);
  final DateTime startInstant = eventScheduleInstantLocal(dateOnly, start);
  DateTime endCandidate = eventScheduleInstantLocal(dateOnly, end);
  if (!EcoEvent.isValidRange(start, end)) {
    endCandidate = startInstant.add(Duration(hours: defaultDurationHours));
  }
  if (!endCandidate.isAfter(earliestEnd)) {
    endCandidate = earliestEnd.add(const Duration(minutes: 1));
    endCandidate = ceilToMinuteGrid(endCandidate);
    if (!endCandidate.isAfter(startInstant) && !endCandidate.isAfter(earliestEnd)) {
      endCandidate = earliestEnd.add(const Duration(minutes: kEventScheduleTimeGridMinutes));
      endCandidate = ceilToMinuteGrid(endCandidate);
    }
  }
  EventTime endResult = eventTimeFromDateTime(endCandidate);
  if (!EcoEvent.isValidRange(start, endResult)) {
    endCandidate = ceilToMinuteGrid(
      startInstant.add(Duration(hours: defaultDurationHours)),
    );
    endResult = eventTimeFromDateTime(endCandidate);
  }
  if (!endCandidate.isAfter(earliestEnd)) {
    endCandidate = ceilToMinuteGrid(earliestEnd.add(const Duration(minutes: 1)));
    endResult = eventTimeFromDateTime(endCandidate);
  }
  return (start: start, end: endResult);
}

/// Minimum time for Cupertino start picker (shell date 2000-01-01). Null = no minimum.
DateTime? pickerMinimumForStart({
  required DateTime dateOnly,
  required DateTime now,
  Duration minLead = kEventScheduleMinLead,
}) {
  final DateTime today = DateUtils.dateOnly(now);
  if (dateOnly.isBefore(today)) {
    return _pickerShell(0, 0);
  }
  if (dateOnly.isAfter(today)) {
    return null;
  }
  return _pickerShellFromInstant(_earliestStartInstant(now, minLead));
}

DateTime _pickerShellFromInstant(DateTime dt) => _pickerShell(dt.hour, dt.minute);

/// Minimum time for end picker on the event day (shell date 2000-01-01).
DateTime pickerMinimumForEnd({
  required DateTime dateOnly,
  required EventTime start,
  required DateTime now,
  required EcoEventStatus? editStatus,
  Duration minLead = kEventScheduleMinLead,
}) {
  final DateTime startInstant = eventScheduleInstantLocal(dateOnly, start);
  DateTime candidate = ceilToMinuteGrid(
    startInstant.add(const Duration(minutes: 1)),
  );
  final DateTime today = DateUtils.dateOnly(now);
  final DateTime leadInstant = _earliestStartInstant(now, minLead);
  final bool sameDayAsToday = dateOnly.year == today.year &&
      dateOnly.month == today.month &&
      dateOnly.day == today.day;
  final bool enforceLeadFloor =
      editStatus == EcoEventStatus.inProgress || sameDayAsToday;
  if (enforceLeadFloor && !candidate.isAfter(leadInstant)) {
    candidate = ceilToMinuteGrid(leadInstant.add(const Duration(minutes: 1)));
  }
  if (dateOnly.isBefore(today)) {
    return _pickerShellFromInstant(candidate);
  }
  if (!candidate.isAfter(startInstant)) {
    candidate = ceilToMinuteGrid(
      startInstant.add(const Duration(minutes: kEventScheduleTimeGridMinutes)),
    );
  }
  return _pickerShellFromInstant(candidate);
}
