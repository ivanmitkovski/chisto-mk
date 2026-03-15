import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppSmartImage extends StatelessWidget {
  const AppSmartImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final ImageProvider image;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.inputFill),
      child: Image(
        image: image,
        fit: fit,
        semanticLabel: semanticLabel,
        frameBuilder: (
          BuildContext context,
          Widget child,
          int? frame,
          bool wasSynchronouslyLoaded,
        ) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            child: child,
          );
        },
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          return Container(
            color: AppColors.inputFill,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textMuted,
              size: AppSpacing.iconLg,
            ),
          );
        },
      ),
    );
  }
}
