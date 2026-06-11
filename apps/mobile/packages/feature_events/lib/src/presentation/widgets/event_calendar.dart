import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventCalendar extends StatefulWidget {
  const EventCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,

    /// First calendar day that may be selected (inclusive). When null, defaults to today.
    this.minimumSelectableDate,

    /// Last calendar day that may be selected (inclusive). When null, unbounded.
    this.maximumSelectableDate,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? minimumSelectableDate;
  final DateTime? maximumSelectableDate;

  @override
  State<EventCalendar> createState() => _EventCalendarState();
}

class _EventCalendarState extends State<EventCalendar> {
  late DateTime _focusedMonth;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  DateTime get _firstSelectable =>
      DateUtils.dateOnly(widget.minimumSelectableDate ?? _today);

  DateTime? get _lastSelectable {
    final DateTime? max = widget.maximumSelectableDate;
    return max != null ? DateUtils.dateOnly(max) : null;
  }

  bool _isSelectable(DateTime date) {
    final DateTime day = DateUtils.dateOnly(date);
    if (day.isBefore(_firstSelectable)) {
      return false;
    }
    final DateTime? last = _lastSelectable;
    if (last != null && day.isAfter(last)) {
      return false;
    }
    return true;
  }

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
    final bool selectionChanged =
        oldSel == null ||
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

  bool get _canGoToPreviousMonth {
    final DateTime firstAllowed = DateTime(
      _firstSelectable.year,
      _firstSelectable.month,
    );
    final DateTime candidate = DateTime(
      _focusedMonth.year,
      _focusedMonth.month - 1,
    );
    return !candidate.isBefore(firstAllowed);
  }

  bool get _canGoToNextMonth {
    final DateTime? last = _lastSelectable;
    if (last == null) {
      return true;
    }
    final DateTime lastAllowed = DateTime(last.year, last.month);
    final DateTime candidate = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
    );
    return !candidate.isAfter(lastAllowed);
  }

  void _goToPreviousMonth() {
    if (!_canGoToPreviousMonth) {
      return;
    }
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    if (!_canGoToNextMonth) {
      return;
    }
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  List<DateTime?> _buildDayCells() {
    final DateTime firstOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final int weekdayOffset = firstOfMonth.weekday - 1;
    final int daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );

    final List<DateTime?> cells = <DateTime?>[];

    for (int i = 0; i < weekdayOffset; i++) {
      final DateTime prev = firstOfMonth.subtract(
        Duration(days: weekdayOffset - i),
      );
      cells.add(prev);
    }

    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }

    while (cells.length % 7 != 0) {
      cells.add(
        DateTime(
          _focusedMonth.year,
          _focusedMonth.month,
          daysInMonth,
        ).add(Duration(days: cells.length - weekdayOffset - daysInMonth + 1)),
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
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Semantics(
          button: _canGoToPreviousMonth,
          label: context.l10n.eventsCalendarPreviousMonth,
          child: IconButton(
            onPressed: _canGoToPreviousMonth ? _goToPreviousMonth : null,
            splashRadius: 20,
            tooltip: context.l10n.eventsCalendarPreviousMonth,
            icon: Icon(
              CupertinoIcons.chevron_left_circle_fill,
              size: 28,
              color: _canGoToPreviousMonth
                  ? AppColors.primary
                  : AppColors.textMuted.withValues(alpha: 0.35),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          children: <Widget>[
            Text(
              localizations.formatMonthYear(_focusedMonth),
              style: AppTypography.eventsCalendarEmbeddedMonthTitle(
                Theme.of(context).textTheme,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          button: _canGoToNextMonth,
          label: context.l10n.eventsCalendarNextMonth,
          child: IconButton(
            onPressed: _canGoToNextMonth ? _goToNextMonth : null,
            splashRadius: 20,
            tooltip: context.l10n.eventsCalendarNextMonth,
            icon: Icon(
              CupertinoIcons.chevron_right_circle_fill,
              size: 28,
              color: _canGoToNextMonth
                  ? AppColors.primary
                  : AppColors.textMuted.withValues(alpha: 0.35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayLabelsRow(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
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
              style: AppTypography.eventsCalendarWeekdayLabel(
                Theme.of(context).textTheme,
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
              widget.selectedDate != null &&
              _isSameDay(date, widget.selectedDate!);
          final bool selectable = _isSelectable(date);

          return Expanded(
            child: Semantics(
              button: selectable,
              selected: isSelected,
              label: context.l10n.eventsCalendarDaySemantic(date.day),
              child: InkWell(
                onTap: selectable
                    ? () {
                        widget.onDateSelected(date);
                      }
                    : null,
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.fast,
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
                    style: AppTypography.eventsCalendarDayNumber(
                      Theme.of(context).textTheme,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: _dayTextColor(
                        inMonth: inMonth,
                        isSelected: isSelected,
                        isToday: isToday,
                        isDisabled: !selectable,
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
    required bool isDisabled,
  }) {
    if (isSelected) return AppColors.white;
    if (!inMonth) return AppColors.textMuted.withValues(alpha: 0.35);
    if (isToday) return AppColors.primaryDark;
    if (isDisabled) return AppColors.textMuted.withValues(alpha: 0.5);
    return AppColors.textPrimary;
  }
}
