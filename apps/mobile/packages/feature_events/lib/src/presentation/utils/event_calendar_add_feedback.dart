import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_events/src/presentation/utils/event_calendar_add_result.dart';
import 'package:flutter/material.dart';

/// Snackbar + haptics for [EventCalendarAddResult] (shared by detail + date sheet).
void showEventCalendarAddFeedback(
  BuildContext context,
  EventCalendarAddResult result,
) {
  switch (result) {
    case EventCalendarAddResult.added:
      AppHaptics.light();
      AppSnack.show(
        context,
        message: context.l10n.eventsDetailCalendarAdded,
        type: AppSnackType.success,
      );
    case EventCalendarAddResult.alreadyAdded:
      AppHaptics.light();
      AppSnack.show(
        context,
        message: context.l10n.eventsDetailCalendarAlreadyAdded,
        type: AppSnackType.success,
      );
    case EventCalendarAddResult.cancelled:
      break;
    case EventCalendarAddResult.failed:
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsDetailCalendarFailed,
        type: AppSnackType.warning,
      );
  }
}
