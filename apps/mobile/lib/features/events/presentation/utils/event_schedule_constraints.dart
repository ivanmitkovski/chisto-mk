import 'package:flutter/material.dart';

import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

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

/// Last selectable minute on [dateOnly] (same calendar day as start).
DateTime eventScheduleLocalDayEnd(DateTime dateOnly) {
  final DateTime d = DateUtils.dateOnly(dateOnly);
  return DateTime(d.year, d.month, d.day, 23, 59);
}

DateTime _pickerShell(int hour, int minute) =>
    DateTime(2000, 1, 1, hour.clamp(0, 23), minute.clamp(0, 59));

/// Upper bound for end time pickers (shell date `2000-01-01`).
DateTime pickerMaximumForEndSameCalendarDay() => _pickerShell(23, 59);

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
  /// [endInstant] is not strictly after [startInstant].
  endNotAfterStart,

  /// End is after 23:59 on the event's calendar day.
  endAfterLocalDayEnd,

  /// Start is before [earliestStartInstant] (e.g. now + lead on create/upcoming edit).
  startTooSoon,

  /// End is not after now + lead (in-progress edit).
  endTooSoon,
}

DateTime _earliestStartInstant(DateTime now, Duration minLead) {
  return ceilToMinuteGrid(now.add(minLead));
}

/// Validates create flow and **upcoming** edit: same calendar day, end before next day, start lead time.
ScheduleValidationIssue? validateCreateOrUpcomingEditSchedule({
  required DateTime dateOnly,
  required EventTime start,
  required EventTime end,
  required DateTime now,
  Duration minLead = kEventScheduleMinLead,
}) {
  final DateTime d = DateUtils.dateOnly(dateOnly);
  final DateTime startInstant = eventScheduleInstantLocal(d, start);
  final DateTime endInstant = eventScheduleInstantLocal(d, end);
  final DateTime dayEnd = eventScheduleLocalDayEnd(d);
  if (!endInstant.isAfter(startInstant)) {
    return ScheduleValidationIssue.endNotAfterStart;
  }
  if (endInstant.isAfter(dayEnd)) {
    return ScheduleValidationIssue.endAfterLocalDayEnd;
  }
  final DateTime today = DateUtils.dateOnly(now);
  if (d.isBefore(today)) {
    return ScheduleValidationIssue.startTooSoon;
  }
  final DateTime earliest = _earliestStartInstant(now, minLead);
  if (startInstant.isBefore(earliest)) {
    return ScheduleValidationIssue.startTooSoon;
  }
  return null;
}

/// Validates edit while event is in progress: start may be in the past; end must be after now + lead
/// and not after 23:59 on [dateOnly].
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
  final DateTime d = DateUtils.dateOnly(dateOnly);
  final DateTime endInstant = eventScheduleInstantLocal(d, end);
  final DateTime dayEnd = eventScheduleLocalDayEnd(d);
  if (endInstant.isAfter(dayEnd)) {
    return ScheduleValidationIssue.endAfterLocalDayEnd;
  }
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
        dateOnly: DateUtils.dateOnly(dateOnly),
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

/// Keeps [end] on the same [dateOnly] and not after 23:59, strictly after [start] when possible.
EventTime clampEndTimeToEventDay({
  required DateTime dateOnly,
  required EventTime end,
  required EventTime start,
}) {
  final DateTime d = DateUtils.dateOnly(dateOnly);
  final DateTime dayEnd = eventScheduleLocalDayEnd(d);
  DateTime endInstant = eventScheduleInstantLocal(d, end);
  if (endInstant.isAfter(dayEnd)) {
    endInstant = dayEnd;
  }
  final DateTime startInstant = eventScheduleInstantLocal(d, start);
  if (!endInstant.isAfter(startInstant)) {
    endInstant = ceilToMinuteGrid(startInstant.add(const Duration(minutes: 1)));
    if (endInstant.isAfter(dayEnd)) {
      endInstant = dayEnd;
    }
  }
  return eventTimeFromDateTime(endInstant);
}

/// Picks default start/end **times** for create when [dateOnly] is chosen: next grid slot + 2h duration,
/// capped to 23:59 the same calendar day.
({EventTime start, EventTime end}) defaultStartEndForDate({
  required DateTime dateOnly,
  required DateTime now,
  Duration minLead = kEventScheduleMinLead,
  int defaultDurationHours = 2,
}) {
  final DateTime today = DateUtils.dateOnly(now);
  final DateTime d = DateUtils.dateOnly(dateOnly);
  final DateTime dayEnd = eventScheduleLocalDayEnd(d);
  if (d.isBefore(today)) {
    final EventTime s = eventTimeFromDateTime(
      ceilToMinuteGrid(DateTime(today.year, today.month, today.day, 9, 0)),
    );
    DateTime endDt = DateTime(today.year, today.month, today.day, s.hour, s.minute)
        .add(Duration(hours: defaultDurationHours));
    if (endDt.isAfter(dayEnd)) {
      endDt = dayEnd;
    }
    final DateTime startInstant = DateTime(today.year, today.month, today.day, s.hour, s.minute);
    if (!endDt.isAfter(startInstant)) {
      endDt = dayEnd;
    }
    return (start: s, end: eventTimeFromDateTime(endDt));
  }
  if (d.isAfter(today)) {
    const EventTime s = EventTime(hour: 10, minute: 0);
    const EventTime e = EventTime(hour: 12, minute: 0);
    return (start: s, end: e);
  }
  final DateTime startDt = ceilToMinuteGrid(now.add(minLead));
  DateTime endDt = startDt.add(Duration(hours: defaultDurationHours));
  if (endDt.isAfter(dayEnd)) {
    endDt = dayEnd;
  }
  if (!endDt.isAfter(startDt)) {
    endDt = dayEnd;
  }
  return (
    start: eventTimeFromDateTime(startDt),
    end: eventTimeFromDateTime(endDt),
  );
}

/// After date or time change when current pair is invalid, snap for **create** / upcoming.
({EventTime start, EventTime end}) clampCreateOrUpcomingSchedule({
  required DateTime dateOnly,
  required EventTime start,
  required EventTime end,
  required DateTime now,
  Duration minLead = kEventScheduleMinLead,
  int defaultDurationHours = 2,
}) {
  final DateTime d = DateUtils.dateOnly(dateOnly);
  EventTime st = start;
  EventTime en = clampEndTimeToEventDay(dateOnly: d, end: end, start: st);
  ScheduleValidationIssue? issue = validateCreateOrUpcomingEditSchedule(
    dateOnly: d,
    start: st,
    end: en,
    now: now,
    minLead: minLead,
  );
  if (issue == null) {
    return (start: st, end: en);
  }
  final ({EventTime start, EventTime end}) defaults = defaultStartEndForDate(
    dateOnly: d,
    now: now,
    minLead: minLead,
    defaultDurationHours: defaultDurationHours,
  );
  st = defaults.start;
  en = clampEndTimeToEventDay(dateOnly: d, end: defaults.end, start: st);
  issue = validateCreateOrUpcomingEditSchedule(
    dateOnly: d,
    start: st,
    end: en,
    now: now,
    minLead: minLead,
  );
  if (issue == ScheduleValidationIssue.endNotAfterStart ||
      issue == ScheduleValidationIssue.endAfterLocalDayEnd) {
    final DateTime si = eventScheduleInstantLocal(d, st);
    final DateTime dayEnd = eventScheduleLocalDayEnd(d);
    DateTime bumped = ceilToMinuteGrid(si.add(Duration(hours: defaultDurationHours)));
    if (bumped.isAfter(dayEnd)) {
      bumped = dayEnd;
    }
    if (!bumped.isAfter(si)) {
      bumped = dayEnd;
    }
    en = eventTimeFromDateTime(bumped);
  }
  return (start: st, end: en);
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
  final DateTime d = DateUtils.dateOnly(dateOnly);
  EventTime en = clampEndTimeToEventDay(dateOnly: d, end: end, start: start);
  if (validateInProgressEditSchedule(
        dateOnly: d,
        start: start,
        end: en,
        now: now,
        minLead: minLead,
      ) ==
      null) {
    return (start: start, end: en);
  }
  final DateTime earliestEnd = _earliestStartInstant(now, minLead);
  final DateTime startInstant = eventScheduleInstantLocal(d, start);
  DateTime endCandidate = eventScheduleInstantLocal(d, en);
  if (!EcoEvent.isValidRange(start, en)) {
    endCandidate = startInstant.add(Duration(hours: defaultDurationHours));
  }
  final DateTime dayEnd = eventScheduleLocalDayEnd(d);
  if (endCandidate.isAfter(dayEnd)) {
    endCandidate = dayEnd;
  }
  if (!endCandidate.isAfter(earliestEnd)) {
    endCandidate = ceilToMinuteGrid(earliestEnd.add(const Duration(minutes: 1)));
    if (!endCandidate.isAfter(startInstant) && !endCandidate.isAfter(earliestEnd)) {
      endCandidate = ceilToMinuteGrid(
        earliestEnd.add(const Duration(minutes: kEventScheduleTimeGridMinutes)),
      );
    }
  }
  if (endCandidate.isAfter(dayEnd)) {
    endCandidate = dayEnd;
  }
  EventTime endResult = eventTimeFromDateTime(endCandidate);
  if (!EcoEvent.isValidRange(start, endResult)) {
    endCandidate = ceilToMinuteGrid(
      startInstant.add(Duration(hours: defaultDurationHours)),
    );
    if (endCandidate.isAfter(dayEnd)) {
      endCandidate = dayEnd;
    }
    endResult = eventTimeFromDateTime(endCandidate);
  }
  if (!endCandidate.isAfter(earliestEnd)) {
    endCandidate = ceilToMinuteGrid(earliestEnd.add(const Duration(minutes: 1)));
    if (endCandidate.isAfter(dayEnd)) {
      endCandidate = dayEnd;
    }
    endResult = eventTimeFromDateTime(endCandidate);
  }
  endResult = clampEndTimeToEventDay(dateOnly: d, end: endResult, start: start);
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

/// Minimum time for end picker on [dateOnly] (same calendar day as start).
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
  final DateTime dayEndShell = pickerMaximumForEndSameCalendarDay();
  final DateTime candidateShell = _pickerShellFromInstant(candidate);
  if (candidateShell.isAfter(dayEndShell)) {
    return dayEndShell;
  }
  return candidateShell;
}
