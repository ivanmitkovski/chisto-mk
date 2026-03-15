import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';
import 'package:chisto_mobile/shared/widgets/photo_gallery/gallery_image_item.dart';

class GalleryThumbnailRail extends StatelessWidget {
  const GalleryThumbnailRail({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<GalleryImageItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppSpacing.radius18, sigmaY: AppSpacing.radius18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(AppSpacing.radius22),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  'Photos',
                  style: AppTypography.badgeLabel.copyWith(
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (BuildContext context, int index) {
                    final bool isActive = index == currentIndex;
                    return GestureDetector(
                      onTap: () => onSelect(index),
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        curve: AppMotion.emphasized,
                        width: isActive ? 54 : 46,
                        padding: const EdgeInsets.all(AppSpacing.xxs / 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(
                            color: isActive
                                ? AppColors.white.withValues(alpha: 0.9)
                                : AppColors.white.withValues(alpha: 0.16),
                            width: isActive ? 1.4 : 0.9,
                          ),
                          boxShadow: isActive
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.black.withValues(alpha: 0.18),
                                    blurRadius: AppSpacing.radius14,
                                    offset: const Offset(0, AppSpacing.xs),
                                  ),
                                ]
                              : const <BoxShadow>[],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          child: AppSmartImage(image: items[index].image),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
