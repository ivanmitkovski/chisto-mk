import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Month grid with optional server pagination hint when [hasMorePages] stays true
/// but the focused month has no loaded events yet.
class EventsCalendarView extends StatefulWidget {
  const EventsCalendarView({
    super.key,
    required this.events,
    required this.onEventTap,
    this.hasMorePages = false,
    this.onRequestMoreFromServer,
  });

  final List<EcoEvent> events;
  final ValueChanged<EcoEvent> onEventTap;

  /// When true and the focused month is empty in [events], [onRequestMoreFromServer] may run.
  final bool hasMorePages;

  /// Loads the next cursor page (e.g. [EventsRepository.loadMore]). Safe to call multiple times.
  final Future<void> Function()? onRequestMoreFromServer;

  @override
  State<EventsCalendarView> createState() => _EventsCalendarViewState();
}

class _EventsCalendarViewState extends State<EventsCalendarView> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  bool _showIncompleteHint = false;
  static const int _maxAutoPrefetchPages = 5;

  final DateTime _today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    _focusedMonth = _initialFocusedMonth(widget.events);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_prefetchPagesForFocusedMonthIfNeeded());
      }
    });
  }

  @override
  void didUpdateWidget(EventsCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameEventListIdentity(oldWidget.events, widget.events)) {
      _snapFocusedMonthIfNeeded();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_prefetchPagesForFocusedMonthIfNeeded());
        }
      });
    } else if (oldWidget.hasMorePages != widget.hasMorePages) {
      _recomputeIncompleteHint();
    }
  }

  DateTime _initialFocusedMonth(List<EcoEvent> events) {
    if (events.isEmpty) {
      return DateTime(_today.year, _today.month);
    }
    final EcoEvent first = _earliestByStart(events);
    return DateTime(first.date.year, first.date.month);
  }

  void _snapFocusedMonthIfNeeded() {
    if (_selectedDate != null) {
      return;
    }
    final DateTime next = _initialFocusedMonth(widget.events);
    if (_focusedMonth.year != next.year || _focusedMonth.month != next.month) {
      setState(() => _focusedMonth = next);
    }
  }

  EcoEvent _earliestByStart(List<EcoEvent> events) {
    final List<EcoEvent> copy = List<EcoEvent>.from(events);
    copy.sort((EcoEvent a, EcoEvent b) => a.startDateTime.compareTo(b.startDateTime));
    return copy.first;
  }

  bool _sameEventListIdentity(List<EcoEvent> a, List<EcoEvent> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) {
        return false;
      }
    }
    return true;
  }

  /// Lazily computed set of (year, month, day) keys for O(1) lookup per cell.
  Set<int>? _eventDayKeys;
  List<EcoEvent>? _eventDayKeysSource;

  Set<int> _getEventDayKeys() {
    if (_eventDayKeys != null && identical(_eventDayKeysSource, widget.events)) {
      return _eventDayKeys!;
    }
    _eventDayKeysSource = widget.events;
    _eventDayKeys = <int>{
      for (final EcoEvent e in widget.events)
        e.date.year * 10000 + e.date.month * 100 + e.date.day,
    };
    return _eventDayKeys!;
  }

  bool _hasEventOn(DateTime date) {
    return _getEventDayKeys().contains(
      date.year * 10000 + date.month * 100 + date.day,
    );
  }

  bool _monthHasAnyLoadedEvent(DateTime month) {
    return widget.events.any(
      (EcoEvent e) => e.date.year == month.year && e.date.month == month.month,
    );
  }

  List<EcoEvent> get _eventsForSelectedDate {
    if (_selectedDate == null) {
      return <EcoEvent>[];
    }
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
    final int daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
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

  Future<void> _prefetchPagesForFocusedMonthIfNeeded() async {
    if (!widget.hasMorePages || widget.onRequestMoreFromServer == null) {
      _recomputeIncompleteHint();
      return;
    }
    if (_monthHasAnyLoadedEvent(_focusedMonth)) {
      if (mounted) {
        setState(() => _showIncompleteHint = false);
      }
      return;
    }
    int pages = 0;
    while (mounted &&
        pages < _maxAutoPrefetchPages &&
        widget.hasMorePages &&
        !_monthHasAnyLoadedEvent(_focusedMonth)) {
      pages++;
      await widget.onRequestMoreFromServer!.call();
    }
    _recomputeIncompleteHint();
  }

  void _recomputeIncompleteHint() {
    if (!mounted) {
      return;
    }
    final bool hint = widget.hasMorePages &&
        !_monthHasAnyLoadedEvent(_focusedMonth);
    if (hint != _showIncompleteHint) {
      setState(() => _showIncompleteHint = hint);
    }
  }

  Future<void> _onManualLoadMore() async {
    AppHaptics.tap();
    if (widget.onRequestMoreFromServer == null) {
      return;
    }
    await widget.onRequestMoreFromServer!.call();
    if (mounted) {
      _recomputeIncompleteHint();
    }
  }

  void _shiftMonth(int delta) {
    AppHaptics.tap();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
    unawaited(_prefetchPagesForFocusedMonthIfNeeded());
  }

  String _daySemanticsLabel(
    BuildContext context, {
    required int day,
    required bool inMonth,
    required bool hasEvent,
    required bool isSelected,
  }) {
    if (!inMonth) {
      return context.l10n.eventsCalendarDayA11yOutOfMonth(day);
    }
    if (isSelected && hasEvent) {
      return context.l10n.eventsCalendarDayA11ySelectedHasEvents(day);
    }
    if (isSelected) {
      return context.l10n.eventsCalendarDayA11ySelected(day);
    }
    if (hasEvent) {
      return context.l10n.eventsCalendarDayA11yHasEvents(day);
    }
    return context.l10n.eventsCalendarDayA11y(day);
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = _buildDays();
    final List<EcoEvent> selectedEvents = _eventsForSelectedDate;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final List<String> weekdays = <String>[
      ...localizations.narrowWeekdays.sublist(1),
      localizations.narrowWeekdays.first,
    ];
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double gridScale = textScale.clamp(1, 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              onPressed: () => _shiftMonth(-1),
              tooltip: context.l10n.eventsCalendarPreviousMonth,
              icon: const Icon(
                CupertinoIcons.chevron_left,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              localizations.formatMonthYear(_focusedMonth),
              style: AppTypography.eventsCalendarMonthTitle(
                Theme.of(context).textTheme,
              ),
            ),
            IconButton(
              onPressed: () => _shiftMonth(1),
              tooltip: context.l10n.eventsCalendarNextMonth,
              icon: const Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: weekdays
              .map((String w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: AppTypography.eventsCalendarWeekdayLabel(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        MediaQuery.withClampedTextScaling(
          minScaleFactor: 1,
          maxScaleFactor: 1.5,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1 / gridScale,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: days.length,
            itemBuilder: (BuildContext context, int index) {
              final DateTime date = days[index];
              final bool inMonth = date.month == _focusedMonth.month;
              final bool isToday = _isSameDay(date, _today);
              final bool isSelected =
                  _selectedDate != null && _isSameDay(date, _selectedDate!);
              final bool hasEvent = _hasEventOn(date);
              final bool isPast = date.isBefore(_today);

              return Semantics(
                label: _daySemanticsLabel(
                  context,
                  day: date.day,
                  inMonth: inMonth,
                  hasEvent: hasEvent,
                  isSelected: isSelected,
                ),
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
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppMotion.fast,
                    curve: AppMotion.emphasized,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.feedPillSelectedFill
                          : (hasEvent && inMonth
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.transparent),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.feedPillSelectedBorder,
                              width: 1.5,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          '${date.day}',
                          style: AppTypography.eventsCalendarDayNumber(
                            Theme.of(context).textTheme,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.feedPillSelectedForeground
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
        ),
        if (_showIncompleteHint) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.eventsCalendarIncompleteListHint,
            style: AppTypography.eventsSupportingCaption(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.hasMorePages ? _onManualLoadMore : null,
              child: Text(context.l10n.eventsCalendarLoadMoreButton),
            ),
          ),
        ],
        if (_selectedDate != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Text(
            localizations.formatMediumDate(_selectedDate!),
            style: AppTypography.eventsCalendarSectionHeader(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (selectedEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                context.l10n.eventsCalendarNoEventsThisDay,
                style: AppTypography.eventsBodyMuted(Theme.of(context).textTheme),
              ),
            ),
          ...selectedEvents.map(
            (EcoEvent e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: () => widget.onEventTap(e),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: e.status.color.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radius10),
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.eventsCalendarAgendaTitle(
                                  Theme.of(context).textTheme,
                                ),
                              ),
                              Text(
                                e.formattedTimeRange,
                                style: AppTypography.eventsListCardMeta(
                                  Theme.of(context).textTheme,
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
}
