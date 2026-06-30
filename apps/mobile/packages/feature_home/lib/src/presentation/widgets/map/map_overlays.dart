import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/map/map_loading_progress_bar.dart';
import 'package:flutter/material.dart';

export 'map_loading_progress_bar.dart' show MapLoadingProgressBar;

/// Top vignette for chrome contrast.
class TopVignette extends StatelessWidget {
  const TopVignette({
    super.key,
    required this.topPadding,
    this.height = 120,
    this.useDarkTiles = false,
  });

  final double topPadding;
  final double height;
  final bool useDarkTiles;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = useDarkTiles
        ? <Color>[
            AppColors.white.withValues(alpha: 0.14),
            AppColors.white.withValues(alpha: 0.05),
            AppColors.transparent,
          ]
        : <Color>[
            AppColors.black.withValues(alpha: 0.18),
            AppColors.black.withValues(alpha: 0.06),
            AppColors.transparent,
          ];
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: topPadding + height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
              stops: const <double>[0, 0.5, 1],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom vignette for chrome contrast.
class BottomVignette extends StatelessWidget {
  const BottomVignette({
    super.key,
    this.height = 100,
    this.useDarkTiles = false,
  });

  final double height;
  final bool useDarkTiles;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = useDarkTiles
        ? <Color>[
            AppColors.black.withValues(alpha: 0.38),
            AppColors.transparent,
          ]
        : <Color>[
            AppColors.black.withValues(alpha: 0.10),
            AppColors.transparent,
          ];
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: colors,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin top indeterminate bar while map tiles load (no full-screen skeleton).
class TileLoadingOverlay extends StatelessWidget {
  const TileLoadingOverlay({
    super.key,
    required this.showLoading,
    this.isDarkMap = false,
    this.topPadding = 0,
  });

  final bool showLoading;
  final bool isDarkMap;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    if (!showLoading) {
      return const SizedBox.shrink();
    }
    final double safeTop = topPadding > 0
        ? topPadding
        : MediaQuery.paddingOf(context).top;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Padding(
        padding: EdgeInsets.only(top: safeTop),
        child: Semantics(
          liveRegion: true,
          label: context.l10n.mapLoadingSemantic,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ExcludeSemantics(
                child: MapLoadingProgressBar(isDarkMap: isDarkMap),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay shown when no sites match the current filters.
class EmptyFilterOverlay extends StatelessWidget {
  const EmptyFilterOverlay({
    super.key,
    required this.onResetFilters,
    this.useDarkTiles = false,
  });

  final VoidCallback onResetFilters;
  final bool useDarkTiles;

  @override
  Widget build(BuildContext context) {
    return AppEmptyStatePanel(
      icon: Icons.filter_list_off_rounded,
      title: context.l10n.mapEmptyFiltersTitle,
      subtitle: context.l10n.mapEmptyFiltersSubtitle,
      useDarkTiles: useDarkTiles,
      semanticsLabel: context.l10n.mapEmptyFiltersLiveRegion,
      action: AppButton.secondary(
        label: context.l10n.mapResetFiltersSemantic,
        onPressed: onResetFilters,
        leadingIcon: const Icon(Icons.refresh_rounded, size: 18),
        expand: false,
      ),
    );
  }
}
