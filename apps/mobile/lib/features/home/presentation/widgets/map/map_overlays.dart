import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Top vignette for chrome contrast.
class TopVignette extends StatelessWidget {
  const TopVignette({
    super.key,
    required this.topPadding,
    this.height = 120,
  });

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
                Colors.black.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.06),
                Colors.transparent,
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
  const BottomVignette({
    super.key,
    this.height = 100,
  });

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
                Colors.black.withValues(alpha: 0.10),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay shown while map tiles are loading.
class TileLoadingOverlay extends StatelessWidget {
  const TileLoadingOverlay({
    super.key,
    required this.showLoading,
  });

  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: showLoading ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: Container(
            color: AppColors.panelBackground.withValues(alpha: 0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading map…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
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
  const EmptyFilterOverlay({
    super.key,
    required this.onResetFilters,
  });

  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
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
                  label: const Text('Reset filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
