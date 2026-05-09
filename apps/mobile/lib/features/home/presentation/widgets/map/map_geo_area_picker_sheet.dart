import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_panel_bottom_sheet.dart';

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
    AppHaptics.light(context);
    return showAppPanelBottomSheet<String?>(
      context: context,
      builder: (BuildContext sheetContext) {
        final double keyboardInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: MapGeoAreaPickerSheet(
            title: title,
            subtitle: subtitle,
            options: options,
            selectedId: selectedId,
            enableSearch: enableSearch,
          ),
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

    return ReportSheetScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      maxHeightFactor: 0.9,
      addBottomInset: false,
      useModalRouteShape: true,
      trailing: ReportCircleIconButton(
        icon: CupertinoIcons.xmark,
        semanticLabel: context.l10n.semanticClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      titleTextStyle: AppTypography.reportsSheetTitle(textTheme),
      subtitleTextStyle: AppTypography.reportsSheetSubtitle(textTheme),
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: <Widget>[
          if (widget.enableSearch) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            CupertinoSearchTextField(
              controller: _search,
              placeholder: context.l10n.searchModalPlaceholder,
              style: AppTypography.eventsSearchFieldText(textTheme),
              placeholderStyle: AppTypography.eventsSearchFieldPlaceholder(textTheme),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else
            const SizedBox(height: AppSpacing.xs),
          for (final MapGeoAreaOption option in options)
            _GeoOptionRow(
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

class _GeoOptionRow extends StatelessWidget {
  const _GeoOptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600);

    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(label, style: textStyle)),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  size: AppSpacing.iconMd,
                  color: AppColors.primaryDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

