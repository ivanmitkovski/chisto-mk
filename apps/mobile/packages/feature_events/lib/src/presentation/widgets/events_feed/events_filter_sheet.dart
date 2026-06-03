import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:feature_events/src/presentation/utils/events_localized_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    return showAppPanelBottomSheet<EcoEventSearchParams>(
      context: context,
      builder: (BuildContext sheetContext) {
        final double keyboardInset = MediaQuery.viewInsetsOf(
          sheetContext,
        ).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: EventsFilterSheet(current: current),
        );
      },
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
    setState(() {
      if (_categories.contains(cat)) {
        _categories.remove(cat);
      } else {
        _categories.add(cat);
      }
    });
  }

  void _toggleStatus(EcoEventStatus status) {
    setState(() {
      if (_statuses.contains(status)) {
        _statuses.remove(status);
      } else {
        _statuses.add(status);
      }
    });
  }

  void _clearAll() {
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
        : (_dateTo ??
              (_dateFrom ?? DateTime.now()).add(const Duration(days: 7)));
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
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: context.l10n.eventsFilterSheetSemantic,
      child: ReportSheetScaffold(
        title: context.l10n.eventsFilterSheetTitle,
        maxHeightFactor: 0.92,
        addBottomInset: true,
        useModalRouteShape: true,
        titleTextStyle: AppTypographySurfaces.reportsSheetTitle(textTheme),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
                  style: AppTypography.eventsSheetTextLink(textTheme),
                ),
              ),
            ReportCircleIconButton(
              icon: Icons.close_rounded,
              semanticLabel: context.l10n.semanticClose,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        footer: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: AppButton.primary(
            label: _activeCount > 0
                ? context.l10n.eventsFilterSheetActiveCount(_activeCount)
                : context.l10n.eventsFilterSheetShowResults,
            onPressed: _apply,
            expand: true,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SectionLabel(label: context.l10n.eventsFilterSheetCategory),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: EcoEventCategory.values
                      .map((EcoEventCategory cat) {
                        final bool selected = _categories.contains(cat);
                        return AppToggleChip(
                          label: cat.localizedLabel(context.l10n),
                          icon: cat.icon,
                          isActive: selected,
                          onTap: () => _toggleCategory(cat),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionLabel(label: context.l10n.eventsFilterSheetStatus),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children:
                      <EcoEventStatus>[
                            EcoEventStatus.upcoming,
                            EcoEventStatus.inProgress,
                            EcoEventStatus.completed,
                            EcoEventStatus.cancelled,
                          ]
                          .map((EcoEventStatus status) {
                            final bool selected = _statuses.contains(status);
                            return AppToggleChip(
                              label: status.localizedLabel(context.l10n),
                              isActive: selected,
                              accentColor: Color(status.colorValue),
                              onTap: () => _toggleStatus(status),
                            );
                          })
                          .toList(growable: false),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
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
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTypography.eventsSheetSectionLabel(
          Theme.of(context).textTheme,
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
                  ? AppColors.feedPillSelectedFill
                  : AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: hasValue
                    ? AppColors.feedPillSelectedBorder
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
                        style: AppTypography.eventsSheetDateTileLabel(
                          Theme.of(context).textTheme,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs / 2),
                      Text(
                        value,
                        style: AppTypography.eventsSheetDateTileValue(
                          Theme.of(context).textTheme,
                          hasValue: hasValue,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    onPressed: onClear,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
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
