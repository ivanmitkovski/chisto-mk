import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_search_query_chip.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:design_system/src/theme/app_typography_surfaces.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_filter.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:feature_events/src/domain/models/events_list_page_snapshot.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/utils/event_calendar_date_format.dart';
import 'package:feature_events/src/presentation/event_ui_mappers.dart';
import 'package:feature_events/src/presentation/utils/events_localized_strings.dart';
import 'package:feature_events/src/presentation/widgets/date_picker_sheet.dart';
import 'package:feature_events/src/presentation/widgets/events_feed/events_filter_preview_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
/// Inclusive bounds for filter date pickers (matches API query range).
final DateTime kEventsFilterMinDate = DateTime(2020, 1, 1);
final DateTime kEventsFilterMaxDate = DateTime(2030, 12, 31);

const List<EcoEventStatus> _kFilterStatuses = <EcoEventStatus>[
  EcoEventStatus.upcoming,
  EcoEventStatus.inProgress,
  EcoEventStatus.completed,
  EcoEventStatus.cancelled,
];

/// Bottom-sheet filter panel for the events feed.
class EventsFilterSheet extends StatefulWidget {
  const EventsFilterSheet({
    super.key,
    required this.current,
    required this.activeChip,
    required this.repository,
  });

  final EcoEventSearchParams current;
  final EcoEventFilter activeChip;
  final EventsRepository repository;

  static Future<EcoEventSearchParams?> show(
    BuildContext context, {
    required EcoEventSearchParams current,
    required EcoEventFilter activeChip,
    required EventsRepository repository,
  }) {
    return AppBottomSheet.show<EcoEventSearchParams>(
      context: context,
      builder: (BuildContext sheetContext) => EventsFilterSheet(
        current: current,
        activeChip: activeChip,
        repository: repository,
      ),
    );
  }

  @override
  State<EventsFilterSheet> createState() => _EventsFilterSheetState();
}

class _EventsFilterSheetState extends State<EventsFilterSheet> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categorySectionKey = GlobalKey();
  final GlobalKey _statusSectionKey = GlobalKey();
  final GlobalKey _dateSectionKey = GlobalKey();

  late Set<EcoEventCategory> _categories;
  late Set<EcoEventStatus> _statuses;
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  late EventsFilterPreviewController _preview;

  @override
  void initState() {
    super.initState();
    _categories = Set<EcoEventCategory>.from(widget.current.categories);
    _statuses = Set<EcoEventStatus>.from(widget.current.statuses);
    _dateFrom = widget.current.dateFrom;
    _dateTo = widget.current.dateTo;
    _preview = EventsFilterPreviewController(
      repository: widget.repository,
      activeChip: widget.activeChip,
      initialDraft: _draftParams,
    );
    _preview.addListener(_onPreviewChanged);
  }

  EcoEventSearchParams get _draftParams => EcoEventSearchParams(
    categories: _categories,
    statuses: _statuses,
    dateFrom: _dateFrom,
    dateTo: _dateTo,
  );

  bool get _hasDraftFilters =>
      _categories.isNotEmpty ||
      _statuses.isNotEmpty ||
      _dateFrom != null ||
      _dateTo != null;

  bool get _showsChipStatusOverride =>
      _statuses.isNotEmpty &&
      (widget.activeChip == EcoEventFilter.upcoming ||
          widget.activeChip == EcoEventFilter.past);

  void _onPreviewChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _notifyDraftChanged() {
    _preview.updateDraft(_draftParams);
    setState(() {});
  }

  void _toggleCategory(EcoEventCategory cat) {
    AppHaptics.light(context);
    setState(() {
      if (_categories.contains(cat)) {
        _categories.remove(cat);
      } else {
        _categories.add(cat);
      }
    });
    _notifyDraftChanged();
  }

  void _toggleStatus(EcoEventStatus status) {
    AppHaptics.light(context);
    setState(() {
      if (_statuses.contains(status)) {
        _statuses.remove(status);
      } else {
        _statuses.add(status);
      }
    });
    _notifyDraftChanged();
  }

  void _selectAllCategories() {
    setState(() {
      _categories = EcoEventCategory.values.toSet();
    });
    _notifyDraftChanged();
  }

  void _clearCategories() {
    setState(() => _categories = <EcoEventCategory>{});
    _notifyDraftChanged();
  }

  void _selectAllStatuses() {
    setState(() {
      _statuses = _kFilterStatuses.toSet();
    });
    _notifyDraftChanged();
  }

  void _clearStatuses() {
    setState(() => _statuses = <EcoEventStatus>{});
    _notifyDraftChanged();
  }

  void _clearAll() {
    setState(() {
      _categories = <EcoEventCategory>{};
      _statuses = <EcoEventStatus>{};
      _dateFrom = null;
      _dateTo = null;
    });
    _notifyDraftChanged();
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

  void _applyDatePreset({DateTime? from, DateTime? to}) {
    setState(() {
      _dateFrom = from;
      _dateTo = to;
    });
    _notifyDraftChanged();
  }

  void _applyThisWeekPreset() {
    final EcoEventSearchParams week =
        EcoEventSearchParams.discoveryThisSkopjeCalendarWeek(
          DateTime.now().toUtc(),
        );
    _applyDatePreset(from: week.dateFrom, to: week.dateTo);
  }

  void _applyThisMonthPreset() {
    final DateTime now = DateTime.now();
    _applyDatePreset(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month, DateUtils.getDaysInMonth(now.year, now.month)),
    );
  }

  void _applyNext30DaysPreset() {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    _applyDatePreset(from: today, to: today.add(const Duration(days: 30)));
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final DateTime initial = isFrom
        ? (_dateFrom ?? DateTime.now())
        : (_dateTo ??
              (_dateFrom ?? DateTime.now()).add(const Duration(days: 7)));
    final DateTime? minimumDate = isFrom
        ? kEventsFilterMinDate
        : (_dateFrom != null && _dateFrom!.isAfter(kEventsFilterMinDate)
              ? _dateFrom
              : kEventsFilterMinDate);
    final DateTime? maximumDate = isFrom
        ? (_dateTo != null && _dateTo!.isBefore(kEventsFilterMaxDate)
              ? _dateTo
              : kEventsFilterMaxDate)
        : kEventsFilterMaxDate;
    final AppLocalizations l10n = context.l10n;
    final DateTime? picked = await DatePickerSheet.show(
      context,
      title: isFrom
          ? l10n.eventsFilterSheetDateFrom
          : l10n.eventsFilterSheetDateTo,
      initialDate: initial,
      minimumDate: minimumDate,
      maximumDate: maximumDate,
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
    _notifyDraftChanged();
  }

  String _formatDate(BuildContext context, DateTime? d) {
    if (d == null) return '—';
    return formatEventCalendarDate(context, d);
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final BuildContext? sectionContext = key.currentContext;
    if (sectionContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      sectionContext,
      duration: AppMotion.standard,
      curve: AppMotion.smooth,
      alignment: 0.05,
    );
  }

  List<_DraftSummaryChip> _summaryChips(AppLocalizations l10n) {
    final List<_DraftSummaryChip> chips = <_DraftSummaryChip>[];
    for (final EcoEventCategory cat in _categories) {
      chips.add(
        _DraftSummaryChip(
          label: cat.localizedLabel(l10n),
          onTap: () => _scrollToSection(_categorySectionKey),
          onClear: () {
            setState(() => _categories.remove(cat));
            _notifyDraftChanged();
          },
        ),
      );
    }
    for (final EcoEventStatus status in _statuses) {
      chips.add(
        _DraftSummaryChip(
          label: status.localizedLabel(l10n),
          onTap: () => _scrollToSection(_statusSectionKey),
          onClear: () {
            setState(() => _statuses.remove(status));
            _notifyDraftChanged();
          },
        ),
      );
    }
    if (_dateFrom != null) {
      chips.add(
        _DraftSummaryChip(
          label: '${l10n.eventsFilterSheetDateFrom}: ${_formatDate(context, _dateFrom)}',
          onTap: () => _scrollToSection(_dateSectionKey),
          onClear: () {
            setState(() => _dateFrom = null);
            _notifyDraftChanged();
          },
        ),
      );
    }
    if (_dateTo != null) {
      chips.add(
        _DraftSummaryChip(
          label: '${l10n.eventsFilterSheetDateTo}: ${_formatDate(context, _dateTo)}',
          onTap: () => _scrollToSection(_dateSectionKey),
          onClear: () {
            setState(() => _dateTo = null);
            _notifyDraftChanged();
          },
        ),
      );
    }
    return chips;
  }

  Widget _sectionActions({
    required AppLocalizations l10n,
    required VoidCallback onSelectAll,
    required VoidCallback onClear,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppSectionHeaderAction(
          label: l10n.eventsFilterSectionSelectAll,
          onPressed: onSelectAll,
        ),
        AppSectionHeaderAction(
          label: l10n.eventsFilterSectionClear,
          onPressed: onClear,
        ),
      ],
    );
  }

  String _footerLabel(AppLocalizations l10n) {
    final EventsListPageSnapshot? snap = _preview.snapshot;
    if (snap != null && _preview.error == null) {
      if (snap.hasMore) {
        return l10n.eventsFilterShowEventsPlus(snap.count);
      }
      return l10n.eventsFilterShowEvents(snap.count);
    }
    if (_hasDraftFilters) {
      return l10n.eventsFilterSheetShowResults;
    }
    return l10n.eventsFilterSheetShowResults;
  }

  @override
  void dispose() {
    _preview.removeListener(_onPreviewChanged);
    _preview.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<_DraftSummaryChip> summaryChips = _summaryChips(l10n);
    final EventsListPageSnapshot? previewSnap = _preview.snapshot;

    return Semantics(
      container: true,
      label: l10n.eventsFilterSheetSemantic,
      child: ReportSheetScaffold(
        title: l10n.eventsFilterSheetTitle,
        subtitle: l10n.eventsFilterSheetSubtitle,
        maxHeightFactor: 0.92,
        addBottomInset: true,
        useModalRouteShape: true,
        titleTextStyle: AppTypographySurfaces.reportsSheetTitle(textTheme),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Opacity(
              opacity: _hasDraftFilters ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_hasDraftFilters,
                child: AppSectionHeaderAction(
                  label: l10n.eventsFilterSheetClearAll,
                  semanticLabel: l10n.eventsFilterResetSemantic,
                  onPressed: _clearAll,
                ),
              ),
            ),
            ReportCircleIconButton(
              icon: Icons.close_rounded,
              semanticLabel: l10n.semanticClose,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        footer: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: AppButton.primary(
            label: _footerLabel(l10n),
            onPressed: _apply,
            expand: true,
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppFilterSummaryChipShelf(
                chips: summaryChips
                    .map(
                      (_DraftSummaryChip chip) => AppSearchQueryChip(
                        label: chip.label,
                        leadingIcon: Icons.close_rounded,
                        onTap: chip.onClear,
                        semanticLabel: chip.label,
                        maxLabelWidth: 160,
                      ),
                    )
                    .toList(growable: false),
              ),
              if (_showsChipStatusOverride) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppInlineBanner(
                    message: l10n.eventsFilterChipStatusOverrideHint,
                    tone: AppInlineBannerTone.info,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppFilterSheetSection(
                sectionKey: _categorySectionKey,
                title: l10n.eventsFilterSheetCategory,
                contentPadding: EdgeInsets.zero,
                trailing: _sectionActions(
                  l10n: l10n,
                  onSelectAll: _selectAllCategories,
                  onClear: _clearCategories,
                ),
                child: AppFilterInsetGroup(
                  children: EcoEventCategory.values
                      .map((EcoEventCategory cat) {
                        final bool selected = _categories.contains(cat);
                        return AppFilterCheckRow(
                          label: cat.localizedLabel(l10n),
                          leadingIcon: cat.icon,
                          isSelected: selected,
                          onTap: () => _toggleCategory(cat),
                          semanticLabel: cat.localizedLabel(l10n),
                          semanticHint: selected
                              ? l10n.eventsFilterCategoryHintOn
                              : l10n.eventsFilterCategoryHintOff,
                          showDivider: cat != EcoEventCategory.values.last,
                        );
                      })
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppFilterSheetSection(
                sectionKey: _statusSectionKey,
                title: l10n.eventsFilterSheetStatus,
                contentPadding: EdgeInsets.zero,
                trailing: _sectionActions(
                  l10n: l10n,
                  onSelectAll: _selectAllStatuses,
                  onClear: _clearStatuses,
                ),
                child: AppFilterInsetGroup(
                  children: _kFilterStatuses
                      .map((EcoEventStatus status) {
                        final bool selected = _statuses.contains(status);
                        return AppFilterCheckRow(
                          label: status.localizedLabel(l10n),
                          leadingDotColor: Color(status.colorValue),
                          isSelected: selected,
                          onTap: () => _toggleStatus(status),
                          semanticLabel: status.localizedLabel(l10n),
                          semanticHint: selected
                              ? l10n.eventsFilterStatusHintOn
                              : l10n.eventsFilterStatusHintOff,
                          showDivider: status != _kFilterStatuses.last,
                        );
                      })
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppFilterSheetSection(
                sectionKey: _dateSectionKey,
                title: l10n.eventsFilterSheetDateRange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          _DatePresetChip(
                            label: l10n.eventsFilterDatePresetThisWeek,
                            onTap: _applyThisWeekPreset,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _DatePresetChip(
                            label: l10n.eventsFilterDatePresetThisMonth,
                            onTap: _applyThisMonthPreset,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _DatePresetChip(
                            label: l10n.eventsFilterDatePresetNext30Days,
                            onTap: _applyNext30DaysPreset,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _DatePresetChip(
                            label: l10n.eventsFilterDatePresetClear,
                            onTap: () => _applyDatePreset(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DatePickerTile(
                            label: l10n.eventsFilterSheetDateFrom,
                            value: _formatDate(context, _dateFrom),
                            hasValue: _dateFrom != null,
                            onTap: () => _pickDate(isFrom: true),
                            onClear: _dateFrom != null
                                ? () {
                                    setState(() => _dateFrom = null);
                                    _notifyDraftChanged();
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _DatePickerTile(
                            label: l10n.eventsFilterSheetDateTo,
                            value: _formatDate(context, _dateTo),
                            hasValue: _dateTo != null,
                            onTap: () => _pickDate(isFrom: false),
                            onClear: _dateTo != null
                                ? () {
                                    setState(() => _dateTo = null);
                                    _notifyDraftChanged();
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (previewSnap != null && _preview.error == null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  liveRegion: true,
                  label: l10n.eventsFilterPreviewLiveRegion(previewSnap.count),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      l10n.eventsFilterPreviewLiveRegion(previewSnap.count),
                      style: AppTypographySurfaces.homeMutedCaption(
                        textTheme,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftSummaryChip {
  const _DraftSummaryChip({
    required this.label,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onClear;
}

class _DatePresetChip extends StatelessWidget {
  const _DatePresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppToggleChip(
      label: label,
      isActive: false,
      onTap: onTap,
      showDot: false,
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
