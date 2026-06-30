import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/event_ui_mappers.dart';
import 'package:feature_events/src/presentation/utils/event_schedule_constraints.dart';
import 'package:feature_events/src/presentation/widgets/event_calendar.dart';
import 'package:feature_events/src/presentation/widgets/time_range_picker.dart';
import 'package:flutter/material.dart';

class CreateEventScheduleSection extends StatelessWidget {
  const CreateEventScheduleSection({
    super.key,
    required this.sectionKey,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.showError,
    required this.isTimeRangeValid,
    required this.scheduleIssue,
    required this.onDateSelected,
    required this.onStartChanged,
    required this.onEndChanged,
    this.minimumStartPickerTime,
    this.maximumStartPickerTime,
    this.minimumEndPickerTime,
    this.maximumEndPickerTime,
  });

  final Key sectionKey;
  final DateTime? selectedDate;
  final EventTime startTime;
  final EventTime endTime;
  final bool showError;
  final bool isTimeRangeValid;
  final ScheduleValidationIssue? scheduleIssue;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<EventTime> onStartChanged;
  final ValueChanged<EventTime> onEndChanged;
  final DateTime? minimumStartPickerTime;
  final DateTime? maximumStartPickerTime;
  final DateTime? minimumEndPickerTime;
  final DateTime? maximumEndPickerTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.l10n.createEventScheduleDateLabel,
          style: AppTypography.eventsSheetSectionLabel(
            Theme.of(context).textTheme,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        EventCalendar(
          selectedDate: selectedDate,
          onDateSelected: onDateSelected,
        ),
        const SizedBox(height: AppSpacing.lg),
        Divider(
          height: 1,
          thickness: 1,
          color: AppColors.divider.withValues(alpha: 0.55),
        ),
        const SizedBox(height: AppSpacing.lg),
        TimeRangePicker(
          startTime: startTime.toTimeOfDay(),
          endTime: endTime.toTimeOfDay(),
          hasError: showError && (!isTimeRangeValid || scheduleIssue != null),
          minimumStartPickerTime: minimumStartPickerTime,
          maximumStartPickerTime: maximumStartPickerTime,
          minimumEndPickerTime: minimumEndPickerTime,
          maximumEndPickerTime: maximumEndPickerTime,
          onStartChanged: (TimeOfDay t) {
            onStartChanged(EventTimeUI.fromTimeOfDay(t));
          },
          onEndChanged: (TimeOfDay t) {
            onEndChanged(EventTimeUI.fromTimeOfDay(t));
          },
        ),
        if (showError && !isTimeRangeValid) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.createEventEndTimeError,
            style: AppTypography.eventsCaptionStrong(
              Theme.of(context).textTheme,
              color: AppColors.error,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ],
        if (showError &&
            isTimeRangeValid &&
            scheduleIssue ==
                ScheduleValidationIssue.endAfterLocalDayEnd) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.createEventScheduleEndAfterDayError,
            style: AppTypography.eventsCaptionStrong(
              Theme.of(context).textTheme,
              color: AppColors.error,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ],
        if (showError &&
            isTimeRangeValid &&
            scheduleIssue == ScheduleValidationIssue.startTooSoon) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.createEventScheduleStartInPast(
              kEventScheduleMinLead.inMinutes,
            ),
            style: AppTypography.eventsCaptionStrong(
              Theme.of(context).textTheme,
              color: AppColors.error,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ],
        if (showError &&
            isTimeRangeValid &&
            scheduleIssue == ScheduleValidationIssue.endTooSoon) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.createEventScheduleEndInPast(
              kEventScheduleMinLead.inMinutes,
            ),
            style: AppTypography.eventsCaptionStrong(
              Theme.of(context).textTheme,
              color: AppColors.error,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}
