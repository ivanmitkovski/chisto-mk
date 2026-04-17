import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Recurrence preset for the event creation wizard.
enum EventRecurrence {
  none,
  weekly,
  biweekly,
  monthly;

  /// RRULE string sent to the API. Null for [none].
  String? get rrule => switch (this) {
        EventRecurrence.none => null,
        EventRecurrence.weekly => 'FREQ=WEEKLY',
        EventRecurrence.biweekly => 'FREQ=WEEKLY;INTERVAL=2',
        EventRecurrence.monthly => 'FREQ=MONTHLY',
      };

  String label(BuildContext context) => switch (this) {
        EventRecurrence.none => context.l10n.eventsRecurrenceNone,
        EventRecurrence.weekly => context.l10n.eventsRecurrenceWeekly,
        EventRecurrence.biweekly => context.l10n.eventsRecurrenceBiweekly,
        EventRecurrence.monthly => context.l10n.eventsRecurrenceMonthly,
      };
}

/// Result returned by [RecurrencePickerSheet.show].
class RecurrenceSelection {
  const RecurrenceSelection({
    required this.recurrence,
    required this.occurrences,
  });

  final EventRecurrence recurrence;

  /// How many occurrences to create (2–12). Only meaningful when [recurrence] != [EventRecurrence.none].
  final int occurrences;

  String? get rrule => recurrence.rrule;
}

/// Bottom-sheet widget letting the user pick a recurrence preset and occurrence count.
class RecurrencePickerSheet extends StatefulWidget {
  const RecurrencePickerSheet({super.key, this.initial});

  final RecurrenceSelection? initial;

  static Future<RecurrenceSelection?> show(
    BuildContext context, {
    RecurrenceSelection? current,
  }) {
    return showModalBottomSheet<RecurrenceSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => RecurrencePickerSheet(initial: current),
    );
  }

  @override
  State<RecurrencePickerSheet> createState() => _RecurrencePickerSheetState();
}

class _RecurrencePickerSheetState extends State<RecurrencePickerSheet> {
  late EventRecurrence _recurrence;
  late int _occurrences;

  @override
  void initState() {
    super.initState();
    _recurrence = widget.initial?.recurrence ?? EventRecurrence.none;
    _occurrences = widget.initial?.occurrences ?? 4;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPad = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;

    return Container(
      margin: EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.appBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPad > 0 ? 0 : AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
                ),
                child: Text(
                  'Repeat',
                  style: AppTypography.eventsSheetTitle(
                    Theme.of(context).textTheme,
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              // Preset list
              ...EventRecurrence.values.map((EventRecurrence r) {
                final bool selected = _recurrence == r;
                return InkWell(
                  onTap: () {
                    AppHaptics.tap();
                    setState(() => _recurrence = r);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 14,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            r.label(context),
                            style: AppTypography.eventsFormFieldValue(
                              Theme.of(context).textTheme,
                              hasValue: selected,
                            ).copyWith(
                              color: selected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            CupertinoIcons.checkmark,
                            size: 16,
                            color: AppColors.primaryDark,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              // Occurrence count slider (only when a recurrence is selected)
              if (_recurrence != EventRecurrence.none) ...<Widget>[
                const Divider(height: 1, thickness: 0.5),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          context.l10n.eventsRecurrenceOccurrences(_occurrences),
                          style: AppTypography.eventsCalendarAgendaTitle(
                            Theme.of(context).textTheme,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: _occurrences.toDouble(),
                  min: 2,
                  max: 12,
                  divisions: 10,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.divider,
                  label: '$_occurrences',
                  onChanged: (double v) {
                    setState(() => _occurrences = v.round());
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
                ),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    RecurrenceSelection(
                      recurrence: _recurrence,
                      occurrences: _occurrences,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                  child: Text(context.l10n.eventsRecurrenceDone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
