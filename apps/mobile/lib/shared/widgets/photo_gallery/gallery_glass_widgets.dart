import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class GalleryGlassPill extends StatelessWidget {
  const GalleryGlassPill({
    super.key,
    required this.child,
    this.padding,
    this.emphasis = GalleryGlassPillEmphasis.regular,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final GalleryGlassPillEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final bool strong = emphasis == GalleryGlassPillEmphasis.strong;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: strong ? AppSpacing.iconLg : AppSpacing.sm,
          sigmaY: strong ? AppSpacing.iconLg : AppSpacing.sm,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: strong ? 0.3 : 0.22),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
            border: Border.all(
              color: AppColors.white.withValues(alpha: strong ? 0.16 : 0.1),
              width: 0.8,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.12),
                blurRadius: strong ? 14 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}

enum GalleryGlassPillEmphasis { regular, strong }

class GalleryGlassIconButton extends StatelessWidget {
  const GalleryGlassIconButton({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: AppSpacing.sheetHandle + AppSpacing.xs,
          height: AppSpacing.sheetHandle + AppSpacing.xs,
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.14),
              width: 0.8,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.18),
                blurRadius: AppSpacing.iconLg,
                offset: const Offset(0, AppSpacing.sm),
              ),
            ],
          ),
          child: Icon(icon, size: AppSpacing.radius22, color: AppColors.white),
        ),
      ),
    );
  }
}
