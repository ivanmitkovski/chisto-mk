import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Top vignette for chrome contrast.
class TopVignette extends StatelessWidget {
  const TopVignette({super.key, required this.topPadding, this.height = 120});

  final double topPadding;
  final double height;

  @override
  Widget build(BuildContext context) {
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
              colors: <Color>[
                AppColors.black.withValues(alpha: 0.18),
                AppColors.black.withValues(alpha: 0.06),
                AppColors.transparent,
              ],
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
  const BottomVignette({super.key, this.height = 100});

  final double height;

  @override
  Widget build(BuildContext context) {
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
              colors: <Color>[
                AppColors.black.withValues(alpha: 0.10),
                AppColors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder while map tiles load: flat “empty map” tone and a thin top progress bar
/// (similar to Google / Apple Maps—no centered chrome or copy).
class TileLoadingOverlay extends StatelessWidget {
  const TileLoadingOverlay({
    super.key,
    required this.showLoading,
    this.isDarkMap = false,
  });

  final bool showLoading;
  final bool isDarkMap;

  @override
  Widget build(BuildContext context) {
    final Color paper = isDarkMap ? AppColors.mapDarkPaper : AppColors.mapLightPaper;
    final Color track = isDarkMap
        ? AppColors.white.withValues(alpha: 0.08)
        : AppColors.black.withValues(alpha: 0.06);
    final Color value = isDarkMap
        ? AppColors.white.withValues(alpha: 0.55)
        : AppColors.primary.withValues(alpha: 0.85);

    return Positioned.fill(
      child: Semantics(
        liveRegion: true,
        label: showLoading ? 'Loading map' : 'Map loaded',
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: showLoading ? 1 : 0,
            duration: AppMotion.standard,
            curve: AppMotion.smooth,
            child: ColoredBox(
              color: paper,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ExcludeSemantics(
                        child: SizedBox(
                          width: double.infinity,
                          height: 2.5,
                          child: ClipRect(
                            child: LinearProgressIndicator(
                              minHeight: 2.5,
                              backgroundColor: track,
                              valueColor: AlwaysStoppedAnimation<Color>(value),
                            ),
                          ),
                        ),
                      ),
                    ),
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

/// Overlay shown when no sites match the current filters.
class EmptyFilterOverlay extends StatelessWidget {
  const EmptyFilterOverlay({super.key, required this.onResetFilters});

  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'No sites match your current filters',
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.filter_list_off_rounded,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No sites match your filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Try adjusting filters or search.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
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
