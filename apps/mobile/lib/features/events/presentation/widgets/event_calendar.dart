import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class EventCalendar extends StatefulWidget {
  const EventCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<EventCalendar> createState() => _EventCalendarState();
}

class _EventCalendarState extends State<EventCalendar> {
  late DateTime _focusedMonth;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    final DateTime base = widget.selectedDate ?? _today;
    _focusedMonth = DateTime(base.year, base.month);
  }

  @override
  void didUpdateWidget(covariant EventCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final DateTime? next = widget.selectedDate;
    if (next == null) {
      return;
    }
    final DateTime nextMonth = DateTime(next.year, next.month);
    final DateTime? oldSel = oldWidget.selectedDate;
    final bool selectionChanged = oldSel == null ||
        oldSel.year != next.year ||
        oldSel.month != next.month ||
        oldSel.day != next.day;
    if (!selectionChanged) {
      return;
    }
    if (nextMonth.year != _focusedMonth.year ||
        nextMonth.month != _focusedMonth.month) {
      setState(() => _focusedMonth = nextMonth);
    }
  }

  void _goToPreviousMonth() {
    AppHaptics.tap();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    AppHaptics.tap();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  List<DateTime?> _buildDayCells() {
    final DateTime firstOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    int weekdayOffset = firstOfMonth.weekday - 1;
    final int daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);

    final List<DateTime?> cells = <DateTime?>[];

    for (int i = 0; i < weekdayOffset; i++) {
      final DateTime prev = firstOfMonth.subtract(Duration(days: weekdayOffset - i));
      cells.add(prev);
    }

    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }

    while (cells.length % 7 != 0) {
      cells.add(
        DateTime(_focusedMonth.year, _focusedMonth.month, daysInMonth)
            .add(Duration(days: cells.length - weekdayOffset - daysInMonth + 1)),
      );
    }

    return cells;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isCurrentMonth(DateTime date) =>
      date.month == _focusedMonth.month && date.year == _focusedMonth.year;

  @override
  Widget build(BuildContext context) {
    final List<DateTime?> cells = _buildDayCells();
    final int rowCount = cells.length ~/ 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildMonthHeader(context),
        const SizedBox(height: AppSpacing.md),
        _buildDayLabelsRow(context),
        const SizedBox(height: AppSpacing.sm),
        ...List<Widget>.generate(rowCount, (int row) {
          return _buildWeekRow(context, cells.sublist(row * 7, row * 7 + 7));
        }),
      ],
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Semantics(
          button: true,
          label: context.l10n.eventsCalendarPreviousMonth,
          child: IconButton(
            onPressed: _goToPreviousMonth,
            splashRadius: 20,
            tooltip: context.l10n.eventsCalendarPreviousMonth,
            icon: const Icon(
              CupertinoIcons.chevron_left_circle_fill,
              size: 28,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          children: <Widget>[
            Text(
              localizations.formatMonthYear(_focusedMonth),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          button: true,
          label: context.l10n.eventsCalendarNextMonth,
          child: IconButton(
            onPressed: _goToNextMonth,
            splashRadius: 20,
            tooltip: context.l10n.eventsCalendarNextMonth,
            icon: const Icon(
              CupertinoIcons.chevron_right_circle_fill,
              size: 28,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayLabelsRow(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final List<String> dayLabels = <String>[
      ...localizations.narrowWeekdays.sublist(1),
      localizations.narrowWeekdays.first,
    ];
    return Row(
      children: dayLabels.map((String label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekRow(BuildContext context, List<DateTime?> week) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs / 2),
      child: Row(
        children: week.map((DateTime? date) {
          if (date == null) {
            return const Expanded(child: SizedBox.shrink());
          }

          final bool inMonth = _isCurrentMonth(date);
          final bool isToday = _isSameDay(date, _today);
          final bool isSelected =
              widget.selectedDate != null && _isSameDay(date, widget.selectedDate!);
          final bool isPast = date.isBefore(_today);

          return Expanded(
            child: Semantics(
              button: !(isPast && !isToday),
              selected: isSelected,
              label: context.l10n.eventsCalendarDaySemantic(date.day),
              child: InkWell(
                onTap: (isPast && !isToday)
                    ? null
                    : () {
                        AppHaptics.tap();
                        widget.onDateSelected(date);
                      },
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  height: 40,
                  margin: const EdgeInsets.all(AppSpacing.xxs / 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: _dayTextColor(
                        inMonth: inMonth,
                        isSelected: isSelected,
                        isToday: isToday,
                        isPast: isPast,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _dayTextColor({
    required bool inMonth,
    required bool isSelected,
    required bool isToday,
    required bool isPast,
  }) {
    if (isSelected) return AppColors.white;
    if (!inMonth) return AppColors.textMuted.withValues(alpha: 0.35);
    if (isToday) return AppColors.primaryDark;
    if (isPast) return AppColors.textMuted.withValues(alpha: 0.5);
    return AppColors.textPrimary;
  }
}
