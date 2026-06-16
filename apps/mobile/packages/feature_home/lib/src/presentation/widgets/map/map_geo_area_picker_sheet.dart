import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/map/map_geo_area_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MapGeoAreaOption {
  const MapGeoAreaOption({required this.id, required this.label});

  final String? id;
  final String label;
}

class MapGeoAreaPickerSheet extends StatefulWidget {
  const MapGeoAreaPickerSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selectedId,
    this.enableSearch = false,
  });

  final String title;
  final String? subtitle;
  final List<MapGeoAreaOption> options;
  final String? selectedId;
  final bool enableSearch;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<MapGeoAreaOption> options,
    required String? selectedId,
    bool enableSearch = false,
  }) {
    return AppBottomSheet.show<String?>(
      context: context,
      keyboardInsetMode: enableSearch
          ? SheetKeyboardInsetMode.overlay
          : SheetKeyboardInsetMode.lift,
      builder: (BuildContext sheetContext) {
        return MapGeoAreaPickerSheet(
          title: title,
          subtitle: subtitle,
          options: options,
          selectedId: selectedId,
          enableSearch: enableSearch,
        );
      },
    );
  }

  @override
  State<MapGeoAreaPickerSheet> createState() => _MapGeoAreaPickerSheetState();
}

class _MapGeoAreaPickerSheetState extends State<MapGeoAreaPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(_onQueryChanged);
  }

  void _onQueryChanged() => setState(() => _query = _search.text.trim());

  @override
  void dispose() {
    _search.removeListener(_onQueryChanged);
    _search.dispose();
    super.dispose();
  }

  List<MapGeoAreaOption> get _filtered {
    if (!widget.enableSearch) {
      return widget.options;
    }
    final String q = _query.toLowerCase();
    if (q.isEmpty) {
      return widget.options;
    }
    return widget.options
        .where((MapGeoAreaOption o) => o.label.toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _select(MapGeoAreaOption option) {
    Navigator.of(context).pop(option.id);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<MapGeoAreaOption> options = _filtered;
    final String? selectedId = widget.selectedId;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return ReportSheetScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      maxHeightFactor: 0.9,
      fillAvailableHeight: widget.enableSearch,
      addBottomInset: true,
      useModalRouteShape: true,
      trailing: ReportCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: context.l10n.semanticClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      titleTextStyle: AppTypographySurfaces.reportsSheetTitle(textTheme),
      subtitleTextStyle: AppTypographySurfaces.reportsSheetSubtitle(textTheme),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: AppSpacing.lg + keyboardInset),
        children: <Widget>[
          if (widget.enableSearch) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            CupertinoSearchTextField(
              controller: _search,
              placeholder: context.l10n.searchModalPlaceholder,
              style: AppTypography.eventsSearchFieldText(textTheme),
              placeholderStyle: AppTypography.eventsSearchFieldPlaceholder(
                textTheme,
              ),
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else
            const SizedBox(height: AppSpacing.xs),
          for (final MapGeoAreaOption option in options)
            MapGeoAreaOptionRow(
              key: ValueKey<String>('map_geo_option:${option.id ?? 'all'}'),
              label: option.label,
              selected: option.id == selectedId,
              onTap: () => _select(option),
            ),
        ],
      ),
    );
  }
}
