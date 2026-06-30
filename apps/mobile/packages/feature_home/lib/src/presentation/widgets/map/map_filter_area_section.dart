import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/data/map_regions/macedonia_map_regions.dart';
import 'package:feature_home/src/data/map_regions/map_geo_labels.dart';
import 'package:feature_home/src/presentation/widgets/map/map_filter_checklist.dart';
import 'package:feature_home/src/presentation/widgets/map/map_geo_area_list.dart';
import 'package:feature_home/src/presentation/widgets/map/map_geo_area_picker_sheet.dart';
import 'package:flutter/material.dart';

enum _AreaPickerPhase { collapsed, root, skopje }

class MapFilterAreaSection extends StatefulWidget {
  const MapFilterAreaSection({
    super.key,
    required this.geoAreaId,
    required this.onGeoAreaIdChanged,
  });

  final String? geoAreaId;
  final ValueChanged<String?> onGeoAreaIdChanged;

  @override
  State<MapFilterAreaSection> createState() => _MapFilterAreaSectionState();
}

class _MapFilterAreaSectionState extends State<MapFilterAreaSection> {
  _AreaPickerPhase _phase = _AreaPickerPhase.collapsed;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _query = _searchController.text.trim());
  }

  bool get _isExpanded => _phase != _AreaPickerPhase.collapsed;

  void _collapsePicker() {
    _phase = _AreaPickerPhase.collapsed;
    _searchFocusNode.unfocus();
  }

  void _openPickerForCurrentSelection() {
    _phase = _showSkopjeDetail
        ? _AreaPickerPhase.skopje
        : _AreaPickerPhase.root;
  }

  void _toggleHeader() {
    setState(() {
      if (_isExpanded) {
        _collapsePicker();
      } else {
        _openPickerForCurrentSelection();
      }
    });
  }

  void _openRootPicker() {
    setState(() {
      _phase = _AreaPickerPhase.root;
      _searchController.clear();
      _query = '';
    });
  }

  void _openSkopjePicker() {
    setState(() {
      _phase = _AreaPickerPhase.skopje;
      _searchFocusNode.unfocus();
      _searchController.clear();
      _query = '';
    });
  }

  @override
  void didUpdateWidget(MapFilterAreaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_showSkopjeDetail && _phase == _AreaPickerPhase.skopje) {
      _phase = _AreaPickerPhase.collapsed;
    }
  }

  String? _rootValue() {
    final String? id = widget.geoAreaId;
    if (id == null) {
      return null;
    }
    if (MacedoniaMapRegions.isSkopjeMunicipalityId(id) ||
        MacedoniaMapRegions.isSkopjeMetro(id)) {
      return MacedoniaMapRegions.skopjeMetroId;
    }
    return id;
  }

  String _skopjeValue() {
    final String? id = widget.geoAreaId;
    if (id == null || id == MacedoniaMapRegions.skopjeMetroId) {
      return MacedoniaMapRegions.skopjeMetroId;
    }
    if (MacedoniaMapRegions.isSkopjeMunicipalityId(id)) {
      return id;
    }
    return MacedoniaMapRegions.skopjeMetroId;
  }

  bool get _showSkopjeDetail {
    final String? id = widget.geoAreaId;
    return id != null &&
        (MacedoniaMapRegions.isSkopjeMetro(id) ||
            MacedoniaMapRegions.isSkopjeMunicipalityId(id));
  }

  String _currentAreaLabel(AppLocalizations l10n) {
    final String? id = widget.geoAreaId;
    if (id == null) {
      return l10n.mapGeoWholeCountry;
    }
    if (MacedoniaMapRegions.isSkopjeMunicipalityId(id)) {
      return mapGeoRegionTitle(l10n, id);
    }
    if (MacedoniaMapRegions.isSkopjeMetro(id)) {
      return l10n.mapGeoSkopjeWhole;
    }
    return mapGeoRegionTitle(l10n, id);
  }

  List<String> _sortedRootIds(AppLocalizations l10n) {
    final List<String> ids = List<String>.from(
      MacedoniaMapRegions.rootRegionIds,
    );
    ids.sort(
      (String a, String b) =>
          mapGeoRegionTitle(l10n, a).compareTo(mapGeoRegionTitle(l10n, b)),
    );
    return ids;
  }

  List<String> _skopjeDetailOrdered(AppLocalizations l10n) {
    final List<String> raw = List<String>.from(
      MacedoniaMapRegions.skopjeMunicipalityIds,
    );
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

  List<MapGeoAreaOption> _rootOptions(AppLocalizations l10n) {
    final List<MapGeoAreaOption> options = <MapGeoAreaOption>[
      MapGeoAreaOption(id: null, label: l10n.mapGeoWholeCountry),
      ..._sortedRootIds(l10n).map(
        (String id) =>
            MapGeoAreaOption(id: id, label: mapGeoRegionTitle(l10n, id)),
      ),
    ];
    if (_query.isEmpty) {
      return options;
    }
    final String q = _query.toLowerCase();
    return options
        .where((MapGeoAreaOption o) => o.label.toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _onRootSelected(MapGeoAreaOption option) {
    final String? id = option.id;
    if (id == null || id.isEmpty) {
      widget.onGeoAreaIdChanged(null);
      setState(_collapsePicker);
      return;
    }
    if (id == MacedoniaMapRegions.skopjeMetroId) {
      _openSkopjePicker();
      widget.onGeoAreaIdChanged(MacedoniaMapRegions.skopjeMetroId);
      return;
    }
    widget.onGeoAreaIdChanged(id);
    setState(_collapsePicker);
  }

  void _onSkopjeSelected(MapGeoAreaOption option) {
    final String? id = option.id;
    if (id != null) {
      widget.onGeoAreaIdChanged(id);
      setState(_collapsePicker);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String areaLabel = _currentAreaLabel(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MapFilterInsetGroup(
          children: <Widget>[
            Semantics(
              button: true,
              label: '${l10n.mapFilterSectionArea}: $areaLabel',
              expanded: _isExpanded,
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: _toggleHeader,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.place_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              areaLabel,
                              style: AppTypography.textTheme.bodyMedium!
                                  .copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: AppMotion.fast,
                            curve: AppMotion.smooth,
                            child: const Icon(
                              Icons.expand_more_rounded,
                              color: AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: AppMotion.standard,
          curve: AppMotion.smooth,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: MapFilterInsetGroup(
                    children: <Widget>[
                      if (_phase == _AreaPickerPhase.root) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          child: AppCupertinoSearchField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            placeholder: l10n.mapFilterAreaSearchPlaceholder,
                            semanticLabel: l10n.mapFilterAreaSearchPlaceholder,
                            autocorrect: false,
                            textStyle:
                                AppTypographySurfaces.homeSearchFieldText(
                                  textTheme,
                                ),
                            placeholderStyle:
                                AppTypographySurfaces.homeSearchFieldPlaceholder(
                                  textTheme,
                                ),
                            onSubmitted: _searchFocusNode.unfocus,
                            onClear: _searchController.clear,
                          ),
                        ),
                        MapGeoAreaList(
                          options: _rootOptions(l10n),
                          selectedId: _rootValue(),
                          onSelected: _onRootSelected,
                        ),
                      ] else if (_phase == _AreaPickerPhase.skopje) ...<Widget>[
                        Semantics(
                          button: true,
                          label: l10n.mapFilterSectionArea,
                          child: Material(
                            color: AppColors.transparent,
                            child: InkWell(
                              onTap: _openRootPicker,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          l10n.mapFilterSectionArea,
                                          style:
                                              AppTypographySurfaces.homeMutedCaption(
                                                textTheme,
                                              ).copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.xs,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          child: Text(
                            l10n.mapGeoSkopje,
                            style: AppTypographySurfaces.homeMutedCaption(
                              textTheme,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        MapGeoAreaList(
                          options: _skopjeDetailOrdered(l10n)
                              .map(
                                (String id) => MapGeoAreaOption(
                                  id: id,
                                  label: _skopjeSubLabel(l10n, id),
                                ),
                              )
                              .toList(growable: false),
                          selectedId: _skopjeValue(),
                          onSelected: _onSkopjeSelected,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
