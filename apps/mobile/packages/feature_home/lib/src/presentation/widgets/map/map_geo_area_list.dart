import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/map/map_geo_area_picker_sheet.dart';
import 'package:flutter/material.dart';

class MapGeoAreaList extends StatelessWidget {
  const MapGeoAreaList({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    this.maxHeight = 240,
  });

  final List<MapGeoAreaOption> options;
  final String? selectedId;
  final ValueChanged<MapGeoAreaOption> onSelected;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: options.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          thickness: 0.5,
          indent: AppSpacing.md,
          endIndent: AppSpacing.md,
          color: AppColors.divider.withValues(alpha: 0.5),
        ),
        itemBuilder: (BuildContext context, int index) {
          final MapGeoAreaOption option = options[index];
          return MapGeoAreaOptionRow(
            key: ValueKey<String>('map_geo_option:${option.id ?? 'all'}'),
            label: option.label,
            selected: option.id == selectedId,
            onTap: () => onSelected(option),
          );
        },
      ),
    );
  }
}

class MapGeoAreaOptionRow extends StatelessWidget {
  const MapGeoAreaOptionRow({
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
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.bodyMedium!.copyWith(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
