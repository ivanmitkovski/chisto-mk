import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_input_outline.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/data/map_regions/macedonia_map_regions.dart';
import 'package:chisto_mobile/features/home/data/map_regions/map_geo_labels.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_geo_area_picker_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_pollution_type_ui.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_filter_site_status_ui.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class MapFilterSheet extends StatefulWidget {
  const MapFilterSheet({
    super.key,
    required this.activeStatuses,
    required this.activePollutionTypes,
    required this.geoAreaId,
    required this.visibleCount,
    required this.totalCount,
    required this.allPollutionTypes,
    required this.onToggleStatus,
    required this.onTogglePollutionType,
    required this.onGeoAreaIdChanged,
    required this.includeArchived,
    required this.onIncludeArchivedChanged,
    required this.onDismiss,
    required this.onResetFilters,
  });

  final Set<String> activeStatuses;
  final Set<String> activePollutionTypes;
  final String? geoAreaId;
  final int visibleCount;
  final int totalCount;
  final List<String> allPollutionTypes;
  final void Function(String status) onToggleStatus;
  final void Function(String type) onTogglePollutionType;
  final void Function(String? geoAreaId) onGeoAreaIdChanged;
  final bool includeArchived;
  final void Function(bool value) onIncludeArchivedChanged;
  final VoidCallback onDismiss;
  final VoidCallback onResetFilters;

  @override
  State<MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<MapFilterSheet> {
  late Set<String> _activeStatuses;
  late Set<String> _activePollutionTypes;
  String? _geoAreaId;
  late bool _includeArchived;

  @override
  void initState() {
    super.initState();
    _activeStatuses = Set<String>.from(widget.activeStatuses);
    _activePollutionTypes = Set<String>.from(widget.activePollutionTypes);
    _geoAreaId = widget.geoAreaId;
    _includeArchived = widget.includeArchived;
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_activeStatuses.contains(status)) {
        if (_activeStatuses.length == 1) {
          return;
        }
        _activeStatuses.remove(status);
      } else {
        _activeStatuses.add(status);
      }
    });
    widget.onToggleStatus(status);
    AppHaptics.pinSelect(context);
  }

  void _toggleType(String type) {
    setState(() {
      if (_activePollutionTypes.contains(type)) {
        if (_activePollutionTypes.length == 1) {
          return;
        }
        _activePollutionTypes.remove(type);
      } else {
        _activePollutionTypes.add(type);
      }
    });
    widget.onTogglePollutionType(type);
    AppHaptics.pinSelect(context);
  }

  void _onGeoChanged(String? next) {
    setState(() => _geoAreaId = next);
    widget.onGeoAreaIdChanged(next);
    AppHaptics.light(context);
  }

  void _onRootAreaChanged(String? next) {
    if (next == null || next.isEmpty) {
      _onGeoChanged(null);
      return;
    }
    if (next == MacedoniaMapRegions.skopjeMetroId) {
      _onGeoChanged(MacedoniaMapRegions.skopjeMetroId);
      return;
    }
    _onGeoChanged(next);
  }

  void _onSkopjeDetailChanged(String next) {
    _onGeoChanged(next);
  }

  List<String> _sortedRootIds(AppLocalizations l10n) {
    final List<String> ids = List<String>.from(MacedoniaMapRegions.rootRegionIds);
    ids.sort(
      (String a, String b) =>
          mapGeoRegionTitle(l10n, a).compareTo(mapGeoRegionTitle(l10n, b)),
    );
    return ids;
  }

  List<String> _skopjeDetailOrdered(AppLocalizations l10n) {
    final List<String> raw = List<String>.from(MacedoniaMapRegions.skopjeMunicipalityIds);
    if (raw.isEmpty) {
      return raw;
    }
    final String metro = raw.first;
    final List<String> rest = List<String>.from(raw.sublist(1))
      ..sort(
        (String a, String b) =>
            mapGeoRegionTitle(l10n, a).compareTo(mapGeoRegionTitle(l10n, b)),
      );
    return <String>[metro, ...rest];
  }

  String _skopjeSubLabel(AppLocalizations l10n, String id) {
    if (id == MacedoniaMapRegions.skopjeMetroId) {
      return l10n.mapGeoSkopjeWhole;
    }
    return mapGeoRegionTitle(l10n, id);
  }

  bool get _showSkopjeDetail =>
      _geoAreaId != null &&
      (MacedoniaMapRegions.isSkopjeMetro(_geoAreaId!) ||
          MacedoniaMapRegions.isSkopjeMunicipalityId(_geoAreaId!));

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final int visibleCount = widget.visibleCount;
    final List<String> sortedRoots = _sortedRootIds(l10n);
    final TextStyle? areaValueTextStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.mapFilterSheetTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            AppHaptics.medium(context);
                            widget.onResetFilters();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.primaryDark,
                            textStyle:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1,
                                    ),
                          ),
                          child: Text(l10n.mapResetFiltersSemantic),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: AppColors.textMuted,
                    tooltip: l10n.mapFilterCloseTooltip,
                    onPressed: () {
                      AppHaptics.sheetDismiss(context);
                      widget.onDismiss();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilterSection(
                title: l10n.mapFilterSectionArea,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Semantics(
                      label: l10n.mapFilterSectionArea,
                      button: true,
                      child: _GeoPickerField(
                        label: _rootDropdownValue() == null
                            ? l10n.mapGeoWholeCountry
                            : mapGeoRegionTitle(l10n, _rootDropdownValue()!),
                        textStyle: areaValueTextStyle,
                        onTap: () async {
                          final String? next = await MapGeoAreaPickerSheet.show(
                            context,
                            title: l10n.mapFilterSectionArea,
                            options: <MapGeoAreaOption>[
                              MapGeoAreaOption(
                                id: null,
                                label: l10n.mapGeoWholeCountry,
                              ),
                              ...sortedRoots.map(
                                (String id) => MapGeoAreaOption(
                                  id: id,
                                  label: mapGeoRegionTitle(l10n, id),
                                ),
                              ),
                            ],
                            selectedId: _rootDropdownValue(),
                            enableSearch: true,
                          );
                          _onRootAreaChanged(next);
                        },
                      ),
                    ),
                    AnimatedSize(
                      duration: AppMotion.standard,
                      curve: AppMotion.smooth,
                      alignment: Alignment.topCenter,
                      child: _showSkopjeDetail
                          ? Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Semantics(
                                label: l10n.mapGeoSkopje,
                                button: true,
                                child: _GeoPickerField(
                                  label: _skopjeSubLabel(
                                    l10n,
                                    _skopjeDropdownValue(),
                                  ),
                                  textStyle: areaValueTextStyle,
                                  onTap: () async {
                                    final String? next =
                                        await MapGeoAreaPickerSheet.show(
                                      context,
                                      title: l10n.mapGeoSkopje,
                                      options: _skopjeDetailOrdered(l10n)
                                          .map(
                                            (String id) => MapGeoAreaOption(
                                              id: id,
                                              label: _skopjeSubLabel(l10n, id),
                                            ),
                                          )
                                          .toList(growable: false),
                                      selectedId: _skopjeDropdownValue(),
                                    );
                                    if (next != null) {
                                      _onSkopjeDetailChanged(next);
                                    }
                                  },
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilterSection(
                title: l10n.mapFilterSectionSiteStatus,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: mapStatusOrder.map((String status) {
                    final String display = mapFilterSiteStatusDisplay(l10n, status);
                    return StatusChip(
                      displayLabel: display,
                      color: mapFilterSiteStatusColor(status),
                      isActive: _activeStatuses.contains(status),
                      onTap: () => _toggleStatus(status),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilterSection(
                title: l10n.mapFilterSectionPollutionType,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: widget.allPollutionTypes.map((String type) {
                    final bool isActive = _activePollutionTypes.contains(type);
                    return TypeChip(
                      label: mapPollutionTypeDisplay(l10n, type),
                      isActive: isActive,
                      onTap: () => _toggleType(type),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilterSection(
                title: l10n.mapFilterSectionVisibility,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.mapFilterShowArchivedSites,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _includeArchived,
                      onChanged: (bool value) {
                        setState(() => _includeArchived = value);
                        widget.onIncludeArchivedChanged(value);
                        AppHaptics.light(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                liveRegion: true,
                label: l10n.mapFilterShowingLiveRegion(
                  visibleCount,
                  widget.totalCount,
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  transitionBuilder: (Widget child, Animation<double> a) =>
                      FadeTransition(opacity: a, child: child),
                  child: Text(
                    l10n.mapFilterShowingInline(visibleCount, widget.totalCount),
                    key: ValueKey<int>(visibleCount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

  /// Root dropdown: null = whole country; Skopje metro vs Skopje muni both show as Skopje in first control when in Skopje scope.
  String? _rootDropdownValue() {
    final String? id = _geoAreaId;
    if (id == null) {
      return null;
    }
    if (MacedoniaMapRegions.isSkopjeMunicipalityId(id) ||
        MacedoniaMapRegions.isSkopjeMetro(id)) {
      return MacedoniaMapRegions.skopjeMetroId;
    }
    return id;
  }

  String _skopjeDropdownValue() {
    final String? id = _geoAreaId;
    if (id == null || id == MacedoniaMapRegions.skopjeMetroId) {
      return MacedoniaMapRegions.skopjeMetroId;
    }
    if (MacedoniaMapRegions.isSkopjeMunicipalityId(id)) {
      return id;
    }
    return MacedoniaMapRegions.skopjeMetroId;
  }
}

class FilterSection extends StatelessWidget {
  const FilterSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GeoPickerField extends StatelessWidget {
  const _GeoPickerField({
    required this.label,
    required this.onTap,
    required this.textStyle,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: InputDecorator(
          decoration: appOutlineInputDecoration(),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(label, style: textStyle)),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.expand_more_rounded,
                size: AppSpacing.iconMd,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TypeChip extends StatelessWidget {
  const TypeChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Semantics(
      button: true,
      toggled: isActive,
      label: l10n.mapFilterPollutionTypeSemantic(label),
      hint: isActive
          ? l10n.mapFilterPollutionTypeHintOn
          : l10n.mapFilterPollutionTypeHintOff,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.radius14,
            vertical: AppSpacing.radius10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.displayLabel,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final String displayLabel;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color textColor = isActive
        ? AppColors.textPrimary
        : AppColors.textMuted.withValues(alpha: 0.85);
    final Color background = isActive
        ? color.withValues(alpha: 0.12)
        : AppColors.white.withValues(alpha: 0.35);

    return Semantics(
      button: true,
      toggled: isActive,
      label: l10n.mapFilterSiteStatusSemantic(displayLabel),
      hint: isActive ? l10n.mapFilterSiteStatusHintOn : l10n.mapFilterSiteStatusHintOff,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.5) : AppColors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isActive ? 1 : 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                displayLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
