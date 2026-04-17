import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

/// Single validation model for create-event: keep UI [ _isValid ] and step progress
/// ([_completedSteps]) aligned with the same rules.
bool createEventFormIsSubmittable({
  required bool hasSite,
  required bool hasDate,
  required EcoEventCategory? category,
  required String titleTrimmed,
  required bool timeRangeValid,
  required bool scheduleValid,
}) {
  return hasSite &&
      hasDate &&
      category != null &&
      titleTrimmed.length >= 3 &&
      timeRangeValid &&
      scheduleValid;
}

/// Milestones: site, date, valid time range, title (≥3 chars), category.
int createEventFormCompletedSteps({
  required bool hasSite,
  required bool hasDate,
  required EcoEventCategory? category,
  required String titleTrimmed,
  required bool timeRangeValid,
  required bool scheduleValid,
}) {
  int n = 0;
  if (hasSite) {
    n++;
  }
  if (hasDate) {
    n++;
  }
  if (timeRangeValid && scheduleValid) {
    n++;
  }
  if (titleTrimmed.length >= 3) {
    n++;
  }
  if (category != null) {
    n++;
  }
  return n;
}
