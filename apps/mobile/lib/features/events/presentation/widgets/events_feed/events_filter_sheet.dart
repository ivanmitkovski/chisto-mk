import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Bottom-sheet filter panel for the events feed.
///
/// Shows category multi-select chips, status toggles, and a date range picker.
/// Returns the selected [EcoEventSearchParams] via [show], or null when the
/// user dismisses without applying.
class EventsFilterSheet extends StatefulWidget {
  const EventsFilterSheet({super.key, required this.current});

  final EcoEventSearchParams current;

  /// Shows the filter sheet modally and returns the result.
  ///
  /// Returns null if the user dismisses without tapping "Show results".
  static Future<EcoEventSearchParams?> show(
    BuildContext context, {
    required EcoEventSearchParams current,
  }) {
    // Modal overlay routes often report zero top viewPadding; use the caller's
    // MediaQuery so the sheet clears the status bar / Dynamic Island / notch.
    final double topInset = MediaQuery.viewPaddingOf(context).top + AppSpacing.sm;
    final double bottomInset = MediaQuery.paddingOf(context).bottom + AppSpacing.sm;
    return showModalBottomSheet<EcoEventSearchParams>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: AppColors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          topInset,
          AppSpacing.sm,
          bottomInset,
        ),
        child: EventsFilterSheet(current: current),
      ),
    );
  }

  @override
  State<EventsFilterSheet> createState() => _EventsFilterSheetState();
}

class _EventsFilterSheetState extends State<EventsFilterSheet> {
  late Set<EcoEventCategory> _categories;
  late Set<EcoEventStatus> _statuses;
  late DateTime? _dateFrom;
  late DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _categories = Set<EcoEventCategory>.from(widget.current.categories);
    _statuses = Set<EcoEventStatus>.from(widget.current.statuses);
    _dateFrom = widget.current.dateFrom;
    _dateTo = widget.current.dateTo;
  }

  void _toggleCategory(EcoEventCategory cat) {
    AppHaptics.tap();
    setState(() {
      if (_categories.contains(cat)) {
        _categories.remove(cat);
      } else {
        _categories.add(cat);
      }
    });
  }

  void _toggleStatus(EcoEventStatus status) {
    AppHaptics.tap();
    setState(() {
      if (_statuses.contains(status)) {
        _statuses.remove(status);
      } else {
        _statuses.add(status);
      }
    });
  }

  void _clearAll() {
    AppHaptics.tap();
    setState(() {
      _categories = <EcoEventCategory>{};
      _statuses = <EcoEventStatus>{};
      _dateFrom = null;
      _dateTo = null;
    });
  }

  void _apply() {
    final EcoEventSearchParams result = widget.current.copyWith(
      categories: _categories,
      statuses: _statuses,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      clearDateFrom: _dateFrom == null,
      clearDateTo: _dateTo == null,
    );
    Navigator.of(context).pop(result);
  }

  int get _activeCount =>
      _categories.length +
      _statuses.length +
      (_dateFrom != null ? 1 : 0) +
      (_dateTo != null ? 1 : 0);

  Future<void> _pickDate({required bool isFrom}) async {
    final DateTime initial = isFrom
        ? (_dateFrom ?? DateTime.now())
        : (_dateTo ?? (_dateFrom ?? DateTime.now()).add(const Duration(days: 7)));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: AppColors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
        if (_dateTo != null && _dateTo!.isBefore(picked)) {
          _dateTo = picked;
        }
      } else {
        _dateTo = picked;
        if (_dateFrom != null && _dateFrom!.isAfter(picked)) {
          _dateFrom = picked;
        }
      }
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPad = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;

    return Semantics(
      container: true,
      label: context.l10n.eventsFilterSheetSemantic,
      child: Container(
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
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  width: AppSpacing.sheetHandle,
                  height: AppSpacing.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.sheetHandleHeight / 2,
                    ),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.sm, AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.l10n.eventsFilterSheetTitle,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (_activeCount > 0)
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        minimumSize: const Size(44, 44),
                        onPressed: _clearAll,
                        child: Text(
                          context.l10n.eventsFilterSheetClearAll,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.5),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Category section
                      _SectionLabel(label: context.l10n.eventsFilterSheetCategory),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: EcoEventCategory.values.map((EcoEventCategory cat) {
                            final bool selected = _categories.contains(cat);
                            return _FilterChip(
                              label: cat.localizedLabel(context.l10n),
                              icon: IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                              selected: selected,
                              onTap: () => _toggleCategory(cat),
                            );
                          }).toList(growable: false),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Status section
                      _SectionLabel(label: context.l10n.eventsFilterSheetStatus),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: <EcoEventStatus>[
                            EcoEventStatus.upcoming,
                            EcoEventStatus.inProgress,
                            EcoEventStatus.completed,
                            EcoEventStatus.cancelled,
                          ].map((EcoEventStatus status) {
                            final bool selected = _statuses.contains(status);
                            return _FilterChip(
                              label: status.localizedLabel(context.l10n),
                              selected: selected,
                              color: Color(status.colorValue),
                              onTap: () => _toggleStatus(status),
                            );
                          }).toList(growable: false),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Date range section
                      _SectionLabel(label: context.l10n.eventsFilterSheetDateRange),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: _DatePickerTile(
                                label: context.l10n.eventsFilterSheetDateFrom,
                                value: _formatDate(_dateFrom),
                                hasValue: _dateFrom != null,
                                onTap: () => _pickDate(isFrom: true),
                                onClear: _dateFrom != null
                                    ? () => setState(() => _dateFrom = null)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _DatePickerTile(
                                label: context.l10n.eventsFilterSheetDateTo,
                                value: _formatDate(_dateTo),
                                hasValue: _dateTo != null,
                                onTap: () => _pickDate(isFrom: false),
                                onClear: _dateTo != null
                                    ? () => setState(() => _dateTo = null)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
                ),
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                  child: Text(
                    _activeCount > 0
                        ? context.l10n.eventsFilterSheetActiveCount(_activeCount)
                        : context.l10n.eventsFilterSheetShowResults,
                    style: AppTypography.textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color accent = color ?? AppColors.primary;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.14)
                  : AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.5)
                    : AppColors.divider.withValues(alpha: 0.6),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    size: 14,
                    color: selected ? accent : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                ] else if (color != null) ...<Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: selected ? accent : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: hasValue
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: hasValue
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.divider.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        label,
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs / 2),
                      Text(
                        value,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: hasValue
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontWeight:
                              hasValue ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    onPressed: onClear,
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  )
                else
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
