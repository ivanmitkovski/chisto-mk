import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomReminderDateTimeSheet {
  CustomReminderDateTimeSheet._();

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime eventStart,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = eventStart.subtract(const Duration(minutes: 1));
    if (lastDate.isBefore(firstDate)) {
      return null;
    }
    final DateTime initial = firstDate.isBefore(lastDate)
        ? firstDate.add(const Duration(hours: 1))
        : firstDate;

    return AppBottomSheet.show<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _CustomReminderPickerBody(
            initial: initial,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        );
      },
    );
  }
}

class _CustomReminderPickerBody extends StatefulWidget {
  const _CustomReminderPickerBody({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CustomReminderPickerBody> createState() =>
      _CustomReminderPickerBodyState();
}

class _CustomReminderPickerBodyState extends State<_CustomReminderPickerBody> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  void _onConfirm() {
    if (_selected.isBefore(DateTime.now()) ||
        !_selected.isBefore(widget.lastDate.add(const Duration(minutes: 1)))) {
      return;
    }
    Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return ReportSheetScaffold(
      title: context.l10n.eventsReminderPickTitle,
      maxHeightFactor: 0.5,
      trailing: AppButton.text(
        label: context.l10n.eventsReminderDone,
        onPressed: _onConfirm,
      ),
      child: SizedBox(
        height: 320,
        child: CupertinoTheme(
          data: CupertinoTheme.of(context).copyWith(
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: CupertinoTheme.of(context)
                  .textTheme
                  .dateTimePickerTextStyle
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime,
            use24hFormat: true,
            minimumDate: widget.firstDate,
            maximumDate: widget.lastDate,
            initialDateTime: widget.initial,
            onDateTimeChanged: (DateTime dt) {
              setState(() => _selected = dt);
            },
          ),
        ),
      ),
    );
  }
}
