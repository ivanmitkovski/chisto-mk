import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/presentation/widgets/event_calendar.dart';
import 'package:flutter/material.dart';

/// Design-system date picker presented as a nested bottom sheet.
///
/// Mirrors [TimeRangePicker] chrome: handle, picker body, and confirm CTA.
class DatePickerSheet {
  DatePickerSheet._();

  static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    required DateTime initialDate,
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) {
    final DateTime clampedInitial = _clampDate(
      DateUtils.dateOnly(initialDate),
      minimumDate: minimumDate,
      maximumDate: maximumDate,
    );

    return AppBottomSheet.show<DateTime>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (BuildContext ctx) {
        return _DatePickerSheetBody(
          title: title,
          initialDate: clampedInitial,
          minimumDate: minimumDate,
          maximumDate: maximumDate,
        );
      },
    );
  }

  static DateTime _clampDate(
    DateTime date, {
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) {
    DateTime result = date;
    if (minimumDate != null) {
      final DateTime min = DateUtils.dateOnly(minimumDate);
      if (result.isBefore(min)) {
        result = min;
      }
    }
    if (maximumDate != null) {
      final DateTime max = DateUtils.dateOnly(maximumDate);
      if (result.isAfter(max)) {
        result = max;
      }
    }
    return result;
  }
}

class _DatePickerSheetBody extends StatefulWidget {
  const _DatePickerSheetBody({
    required this.title,
    required this.initialDate,
    this.minimumDate,
    this.maximumDate,
  });

  final String title;
  final DateTime initialDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;

  @override
  State<_DatePickerSheetBody> createState() => _DatePickerSheetBodyState();
}

class _DatePickerSheetBodyState extends State<_DatePickerSheetBody> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
  }

  void _onConfirm() {
    Navigator.of(context).pop(DateUtils.dateOnly(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: AppSpacing.sheetHandle,
            height: AppSpacing.sheetHandleHeight,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              widget.title,
              style: AppTypography.eventsFormLeadHeading(textTheme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: EventCalendar(
              selectedDate: _selected,
              minimumSelectableDate: widget.minimumDate,
              maximumSelectableDate: widget.maximumDate,
              onDateSelected: (DateTime date) {
                setState(() => _selected = DateUtils.dateOnly(date));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: AppButton.primary(
              label: context.l10n.eventsTimePickerConfirm,
              onPressed: _onConfirm,
              expand: true,
            ),
          ),
        ],
      ),
    );
  }
}
