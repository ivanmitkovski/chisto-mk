import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class EventsCalendarView extends StatefulWidget {
  const EventsCalendarView({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  final List<EcoEvent> events;
  final ValueChanged<EcoEvent> onEventTap;

  @override
  State<EventsCalendarView> createState() => _EventsCalendarViewState();
}

class _EventsCalendarViewState extends State<EventsCalendarView> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  final DateTime _today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  static const List<String> _weekdays = <String>[
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_today.year, _today.month);
  }

  bool _hasEventOn(DateTime date) {
    return widget.events.any((EcoEvent e) {
      final DateTime d = e.date;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    });
  }

  List<EcoEvent> get _eventsForSelectedDate {
    if (_selectedDate == null) return <EcoEvent>[];
    return widget.events
        .where((EcoEvent e) {
          final DateTime d = e.date;
          return d.year == _selectedDate!.year &&
              d.month == _selectedDate!.month &&
              d.day == _selectedDate!.day;
        })
        .toList()
      ..sort((EcoEvent a, EcoEvent b) => a.date.compareTo(b.date));
  }

  List<DateTime> _buildDays() {
    final DateTime first =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final int startOffset = first.weekday - 1;
    final int daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final List<DateTime> days = <DateTime>[];
    for (int i = 0; i < startOffset; i++) {
      days.add(first.subtract(Duration(days: startOffset - i)));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    final int remainder = 7 - (days.length % 7);
    if (remainder < 7) {
      final DateTime last = days.last;
      for (int i = 1; i <= remainder; i++) {
        days.add(last.add(Duration(days: i)));
      }
    }
    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = _buildDays();
    final List<EcoEvent> selectedEvents = _eventsForSelectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              onPressed: () {
                AppHaptics.tap();
                setState(() {
                  _focusedMonth = DateTime(
                      _focusedMonth.year, _focusedMonth.month - 1);
                });
              },
              tooltip: 'Previous month',
              icon: const Icon(
                CupertinoIcons.chevron_left,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            IconButton(
              onPressed: () {
                AppHaptics.tap();
                setState(() {
                  _focusedMonth = DateTime(
                      _focusedMonth.year, _focusedMonth.month + 1);
                });
              },
              tooltip: 'Next month',
              icon: const Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: _weekdays
              .map((String w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: days.length,
          itemBuilder: (BuildContext context, int index) {
            final DateTime date = days[index];
            final bool inMonth = date.month == _focusedMonth.month;
            final bool isToday = _isSameDay(date, _today);
            final bool isSelected = _selectedDate != null &&
                _isSameDay(date, _selectedDate!);
            final bool hasEvent = _hasEventOn(date);
            final bool isPast = date.isBefore(_today);

            return Semantics(
              label: 'Day ${date.day}',
              button: inMonth,
              selected: isSelected,
              child: GestureDetector(
                onTap: inMonth
                    ? () {
                        AppHaptics.light();
                        setState(() => _selectedDate = date);
                      }
                    : null,
                child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.emphasized,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (hasEvent && inMonth
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${date.day}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : inMonth
                                ? (isPast && !isToday
                                    ? AppColors.textMuted.withValues(alpha: 0.5)
                                    : AppColors.textPrimary)
                                : AppColors.textMuted.withValues(alpha: 0.35),
                      ),
                    ),
                    if (hasEvent && inMonth && !isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            );
          },
        ),
        if (_selectedDate != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Text(
            _formatDate(_selectedDate!),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (selectedEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'No events on this day',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ),
          ...selectedEvents.map(
            (EcoEvent e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onEventTap(e),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: e.status.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            e.category.icon,
                            size: 20,
                            color: e.status.color,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                e.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                e.formattedTimeRange,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _monthName(int month) {
    const List<String> names = <String>[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }

  String _formatDate(DateTime d) {
    return '${_monthName(d.month)} ${d.day}, ${d.year}';
  }
}
