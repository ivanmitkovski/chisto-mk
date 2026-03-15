import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

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

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (BuildContext sheetContext) {
        return _CustomReminderPickerBody(
          initial: initial,
          firstDate: firstDate,
          lastDate: lastDate,
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
  State<_CustomReminderPickerBody> createState() => _CustomReminderPickerBodyState();
}

class _CustomReminderPickerBodyState extends State<_CustomReminderPickerBody> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  void _onConfirm() {
    if (_selected.isBefore(DateTime.now()) || !_selected.isBefore(widget.lastDate.add(const Duration(minutes: 1)))) {
      return;
    }
    AppHaptics.tap();
    Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 360,
        child: Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: AppSpacing.sheetHandle,
                height: AppSpacing.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppSpacing.sheetHandleHeight / 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Pick reminder',
                    style: AppTypography.sheetTitle,
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    onPressed: _onConfirm,
                    child: Text(
                      'Done',
                      style: AppTypography.pillLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoTheme.of(context).copyWith(
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: CupertinoTheme.of(context).textTheme.dateTimePickerTextStyle.copyWith(
                      color: AppColors.textPrimary,
                    ),
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
          ],
        ),
      ),
    );
  }
}
