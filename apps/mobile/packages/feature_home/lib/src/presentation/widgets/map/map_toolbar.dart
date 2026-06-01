import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_sites_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_ui_mode_notifier.dart';
import 'package:feature_home/src/presentation/utils/map_site_filter.dart';
import 'package:feature_home/src/presentation/widgets/map/map_actions_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top controls row for map filtering, search, and compass.
class MapToolbar extends ConsumerWidget {
  const MapToolbar({
    super.key,
    required this.visibleCount,
    required this.rotationLocked,
    required this.rotationDegrees,
    required this.onOpenFilters,
    required this.onOpenSearch,
    required this.onResetRotation,
  });

  final int visibleCount;
  final bool rotationLocked;
  final double rotationDegrees;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenSearch;
  final VoidCallback onResetRotation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MapFilterState filterState = ref.watch(mapFilterNotifierProvider);
    final bool useDarkTiles = ref.watch(
      mapUiModeNotifierProvider.select((MapUiModeState m) => m.useDarkTiles),
    );
    final bool staleFallback = ref.watch(
      mapSitesNotifierProvider.select(
        (MapSitesState s) => s.isUsingPersistedFallback,
      ),
    );
    final bool hasFilterActive = mapFilterHasNonDefault(filterState);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.35,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MapFilterButton(
            visibleCount: visibleCount,
            hasFilterActive: hasFilterActive,
            useDarkTiles: useDarkTiles,
            showStaleCacheBadge: staleFallback,
            onTap: onOpenFilters,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  MapSearchIconButton(
                    onTap: onOpenSearch,
                    useDarkTiles: useDarkTiles,
                  ),
                ],
              ),
              if (!rotationLocked) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                MapCompassButton(
                  rotationDegrees: rotationDegrees,
                  useDarkTiles: useDarkTiles,
                  onReset: onResetRotation,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
