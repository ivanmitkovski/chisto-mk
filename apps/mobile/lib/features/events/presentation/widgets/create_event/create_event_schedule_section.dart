import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_schedule_constraints.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_calendar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/time_range_picker.dart';

class CreateEventScheduleSection extends StatelessWidget {
  const CreateEventScheduleSection({
    super.key,
    required this.sectionKey,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.showValidationErrors,
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
  final bool showValidationErrors;
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
          hasError: showValidationErrors && (!isTimeRangeValid || scheduleIssue != null),
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
        if (showValidationErrors && !isTimeRangeValid) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.createEventEndTimeError,
            style: AppTypography.eventsCaptionStrong(
              Theme.of(context).textTheme,
              color: AppColors.accentDanger,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ],
        if (showValidationErrors &&
            isTimeRangeValid &&
            scheduleIssue == ScheduleValidationIssue.endAfterLocalDayEnd) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.createEventScheduleEndAfterDayError,
            style: AppTypography.eventsCaptionStrong(
              Theme.of(context).textTheme,
              color: AppColors.accentDanger,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ],
        if (showValidationErrors &&
            isTimeRangeValid &&
            scheduleIssue == ScheduleValidationIssue.startTooSoon) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.createEventScheduleStartInPast(
              kEventScheduleMinLead.inMinutes,
            ),
            style: AppTypography.eventsCaptionStrong(
              Theme.of(context).textTheme,
              color: AppColors.accentDanger,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ],
        if (showValidationErrors &&
            isTimeRangeValid &&
            scheduleIssue == ScheduleValidationIssue.endTooSoon) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.createEventScheduleEndInPast(
              kEventScheduleMinLead.inMinutes,
            ),
            style: AppTypography.eventsCaptionStrong(
              Theme.of(context).textTheme,
              color: AppColors.accentDanger,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}
