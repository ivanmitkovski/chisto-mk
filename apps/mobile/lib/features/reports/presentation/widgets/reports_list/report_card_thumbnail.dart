import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chisto_mobile/core/cache/report_images_cache.dart'
    show reportImagesCache, stableCacheKeyForReportImage;
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class ReportCardThumbnail extends StatelessWidget {
  const ReportCardThumbnail({super.key, required this.pathOrUrl});

  final String pathOrUrl;

  @override
  Widget build(BuildContext context) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: pathOrUrl,
        cacheKey: stableCacheKeyForReportImage(pathOrUrl),
        cacheManager: reportImagesCache,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        memCacheWidth: 216,
        memCacheHeight: 216,
        placeholder: (BuildContext context, String url) => Container(
          color: AppColors.inputFill,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (BuildContext context, String url, Object? error) => Container(
          color: AppColors.inputFill,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textMuted,
            size: AppSpacing.iconLg,
          ),
        ),
      );
    }
    return Image(
      image: FileImage(File(pathOrUrl)),
      fit: BoxFit.cover,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => Container(
        color: AppColors.inputFill,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textMuted,
          size: AppSpacing.iconLg,
        ),
      ),
    );
  }
}
