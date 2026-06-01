import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_search_query_chip.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/data/map_regions/map_geo_labels.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/utils/map_site_filter.dart';
import 'package:feature_home/src/presentation/widgets/map/map_filter_area_section.dart';
import 'package:feature_home/src/presentation/widgets/map/map_filter_checklist.dart';
import 'package:feature_home/src/presentation/widgets/map/map_filter_site_status_ui.dart';
import 'package:feature_home/src/presentation/widgets/map/map_pollution_type_ui.dart';
import 'package:feature_home/src/presentation/widgets/map/map_sheet_launcher.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class MapFilterSheet extends StatefulWidget {
  const MapFilterSheet({
    super.key,
    required this.current,
    required this.allSites,
  });

  final MapFilterState current;
  final List<PollutionSite> allSites;

  static Future<MapFilterState?> show(
    BuildContext context, {
    required MapFilterState current,
    required List<PollutionSite> allSites,
  }) {
    return showMapBottomSheet<MapFilterState>(
      context: context,
      builder: (BuildContext sheetContext) =>
          MapFilterSheet(current: current, allSites: allSites),
    );
  }

  @override
  State<MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<MapFilterSheet> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _areaSectionKey = GlobalKey();
  final GlobalKey _statusSectionKey = GlobalKey();
  final GlobalKey _pollutionSectionKey = GlobalKey();
  final GlobalKey _visibilitySectionKey = GlobalKey();

  late Set<String> _activeStatuses;
  late Set<String> _activePollutionTypes;
  String? _geoAreaId;
  late bool _includeArchived;

  @override
  void initState() {
    super.initState();
    _syncFrom(widget.current);
  }

  void _syncFrom(MapFilterState state) {
    _activeStatuses = Set<String>.from(state.activeStatuses);
    _activePollutionTypes = Set<String>.from(state.activePollutionTypes);
    _geoAreaId = state.geoAreaId;
    _includeArchived = state.includeArchived;
  }

  MapFilterState get _draft => MapFilterState(
    activeStatuses: _activeStatuses,
    activePollutionTypes: _activePollutionTypes,
    geoAreaId: _geoAreaId,
    includeArchived: _includeArchived,
  );

  bool get _hasNonDefaultFilters => mapFilterHasNonDefault(_draft);

  int get _previewCount => mapFilterPreviewCount(widget.allSites, _draft);

  void _resetDraft() {
    setState(() {
      _activeStatuses = Set<String>.from(mapFilterDefaultStatuses);
      _activePollutionTypes = reportPollutionTypeCodes.toSet();
      _geoAreaId = null;
      _includeArchived = false;
    });
  }

  void _apply() {
    Navigator.of(context).pop(_draft);
  }

  void _announceMinSelectionBlocked() {
    AppHaptics.light(context);
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.l10n.mapFilterMinSelectionAnnounce,
      Directionality.of(context),
    );
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_activeStatuses.contains(status)) {
        if (_activeStatuses.length == 1) {
          _announceMinSelectionBlocked();
          return;
        }
        _activeStatuses.remove(status);
      } else {
        _activeStatuses.add(status);
      }
    });
  }

  void _toggleType(String type) {
    setState(() {
      if (_activePollutionTypes.contains(type)) {
        if (_activePollutionTypes.length == 1) {
          _announceMinSelectionBlocked();
          return;
        }
        _activePollutionTypes.remove(type);
      } else {
        _activePollutionTypes.add(type);
      }
    });
  }

  void _selectAllStatuses() {
    setState(() {
      _activeStatuses = Set<String>.from(mapFilterDefaultStatuses);
    });
  }

  void _clearStatuses() {
    if (_activeStatuses.length <= 1) {
      _announceMinSelectionBlocked();
      return;
    }
    setState(() {
      _activeStatuses = <String>{mapFilterStatusOrder.first};
    });
  }

  void _selectAllPollutionTypes() {
    setState(() {
      _activePollutionTypes = reportPollutionTypeCodes.toSet();
    });
  }

  void _clearPollutionTypes() {
    if (_activePollutionTypes.length <= 1) {
      _announceMinSelectionBlocked();
      return;
    }
    setState(() {
      _activePollutionTypes = <String>{reportPollutionTypeCodes.first};
    });
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
    if (_geoAreaId != null) {
      chips.add(
        _DraftSummaryChip(
          label: mapGeoRegionTitle(l10n, _geoAreaId!),
          onTap: () => _scrollToSection(_areaSectionKey),
          onClear: () => setState(() => _geoAreaId = null),
        ),
      );
    }
    if (_includeArchived) {
      chips.add(
        _DraftSummaryChip(
          label: l10n.mapFilterShowArchivedSites,
          onTap: () => _scrollToSection(_visibilitySectionKey),
          onClear: () => setState(() => _includeArchived = false),
        ),
      );
    }
    for (final String status in mapFilterStatusOrder) {
      if (!_activeStatuses.contains(status)) {
        chips.add(
          _DraftSummaryChip(
            label: mapFilterSiteStatusDisplay(l10n, status),
            onTap: () => _scrollToSection(_statusSectionKey),
            onClear: () => setState(() => _activeStatuses.add(status)),
          ),
        );
      }
    }
    for (final String type in reportPollutionTypeCodes) {
      if (!_activePollutionTypes.contains(type)) {
        chips.add(
          _DraftSummaryChip(
            label: mapPollutionTypeDisplay(l10n, type),
            onTap: () => _scrollToSection(_pollutionSectionKey),
            onClear: () => setState(() => _activePollutionTypes.add(type)),
          ),
        );
      }
    }
    return chips;
  }

  Widget _sectionActions({
    required VoidCallback onSelectAll,
    required VoidCallback onClear,
    required AppLocalizations l10n,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppSectionHeaderAction(
          label: l10n.mapFilterSectionSelectAll,
          onPressed: onSelectAll,
        ),
        AppSectionHeaderAction(
          label: l10n.mapFilterSectionClear,
          onPressed: onClear,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<_DraftSummaryChip> summaryChips = _summaryChips(l10n);
    final int previewCount = _previewCount;

    return Semantics(
      container: true,
      label: l10n.mapFilterSheetTitle,
      child: ReportSheetScaffold(
        title: l10n.mapFilterSheetTitle,
        maxHeightFactor: 0.92,
        fillAvailableHeight: true,
        addBottomInset: true,
        scrollChromeWithBody: true,
        titleTextStyle: AppTypographySurfaces.reportsSheetTitle(textTheme),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Opacity(
              opacity: _hasNonDefaultFilters ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_hasNonDefaultFilters,
                child: AppSectionHeaderAction(
                  label: l10n.mapResetFiltersSemantic,
                  onPressed: _resetDraft,
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
            label: l10n.mapFilterShowSites(previewCount),
            onPressed: _apply,
            expand: true,
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MapFilterSummaryChipShelf(
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
              const SizedBox(height: AppSpacing.md),
              AppFilterSheetSection(
                sectionKey: _areaSectionKey,
                title: l10n.mapFilterSectionArea,
                contentPadding: EdgeInsets.zero,
                child: MapFilterAreaSection(
                  geoAreaId: _geoAreaId,
                  onGeoAreaIdChanged: (String? next) {
                    setState(() => _geoAreaId = next);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppFilterSheetSection(
                sectionKey: _statusSectionKey,
                title: l10n.mapFilterSectionSiteStatus,
                contentPadding: EdgeInsets.zero,
                trailing: _sectionActions(
                  l10n: l10n,
                  onSelectAll: _selectAllStatuses,
                  onClear: _clearStatuses,
                ),
                child: MapFilterInsetGroup(
                  children: mapFilterStatusOrder
                      .map((String status) {
                        final String display = mapFilterSiteStatusDisplay(
                          l10n,
                          status,
                        );
                        final bool isSelected = _activeStatuses.contains(
                          status,
                        );
                        return MapFilterCheckRow(
                          label: display,
                          leadingDotColor: mapFilterSiteStatusColor(status),
                          isSelected: isSelected,
                          onTap: () => _toggleStatus(status),
                          semanticLabel: l10n.mapFilterSiteStatusSemantic(
                            display,
                          ),
                          semanticHint: isSelected
                              ? l10n.mapFilterSiteStatusHintOn
                              : l10n.mapFilterSiteStatusHintOff,
                          showDivider: status != mapFilterStatusOrder.last,
                        );
                      })
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppFilterSheetSection(
                sectionKey: _pollutionSectionKey,
                title: l10n.mapFilterSectionPollutionType,
                contentPadding: EdgeInsets.zero,
                trailing: _sectionActions(
                  l10n: l10n,
                  onSelectAll: _selectAllPollutionTypes,
                  onClear: _clearPollutionTypes,
                ),
                child: MapFilterInsetGroup(
                  children: reportPollutionTypeCodes
                      .map((String type) {
                        final String display = mapPollutionTypeDisplay(
                          l10n,
                          type,
                        );
                        final bool isSelected = _activePollutionTypes.contains(
                          type,
                        );
                        return MapFilterCheckRow(
                          label: display,
                          isSelected: isSelected,
                          onTap: () => _toggleType(type),
                          semanticLabel: l10n.mapFilterPollutionTypeSemantic(
                            display,
                          ),
                          semanticHint: isSelected
                              ? l10n.mapFilterPollutionTypeHintOn
                              : l10n.mapFilterPollutionTypeHintOff,
                          showDivider: type != reportPollutionTypeCodes.last,
                        );
                      })
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppFilterSheetSection(
                sectionKey: _visibilitySectionKey,
                title: l10n.mapFilterSectionVisibility,
                contentPadding: EdgeInsets.zero,
                child: MapFilterInsetGroup(
                  children: <Widget>[
                    MapFilterSwitchRow(
                      title: l10n.mapFilterShowArchivedSites,
                      subtitle: l10n.mapFilterArchivedSubtitle,
                      value: _includeArchived,
                      semanticLabel: l10n.mapFilterShowArchivedSites,
                      onChanged: (bool value) {
                        setState(() => _includeArchived = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                liveRegion: true,
                label: l10n.mapFilterShowingLiveRegion(
                  previewCount,
                  widget.allSites.length,
                ),
                child: SizedBox(
                  height: 20,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.mapFilterShowingInline(
                        previewCount,
                        widget.allSites.length,
                      ),
                      style: AppTypographySurfaces.homeMutedCaption(
                        textTheme,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
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
