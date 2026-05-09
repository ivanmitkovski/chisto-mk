import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_loading_progress_bar.dart';

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
  const BottomVignette({super.key, this.height = 100, this.useDarkTiles = false});

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
    final Color panelFill = useDarkTiles
        ? AppColors.glassDark.withValues(alpha: 0.58)
        : AppColors.white.withValues(alpha: 0.9);
    final Color panelBorder = useDarkTiles
        ? AppColors.white.withValues(alpha: 0.14)
        : AppColors.white.withValues(alpha: 0.7);
    final Color titleColor =
        useDarkTiles ? AppColors.textOnDark : AppColors.textPrimary;
    final Color bodyColor =
        useDarkTiles ? AppColors.textOnDarkMuted : AppColors.textMuted;
    final Color iconColor =
        useDarkTiles ? AppColors.textOnDarkMuted : AppColors.textMuted;

    return Semantics(
      liveRegion: true,
      label: context.l10n.mapEmptyFiltersLiveRegion,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: panelFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: panelBorder,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.filter_list_off_rounded,
                    size: 48,
                    color: iconColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.mapEmptyFiltersTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.mapEmptyFiltersSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: bodyColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onResetFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(context.l10n.mapResetFiltersSemantic),
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
