import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/cache/report_images_cache.dart'
    show reportImagesCache, stableCacheKeyForReportImage;

ImageProvider imageProviderForReportEvidence(
  String pathOrUrl, {
  int? maxWidth,
  int? maxHeight,
}) {
  final ImageProvider<Object> base =
      pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')
          ? CachedNetworkImageProvider(
              pathOrUrl,
              cacheManager: reportImagesCache,
              cacheKey: stableCacheKeyForReportImage(pathOrUrl),
            )
          : FileImage(File(pathOrUrl));

  // maxWidth/maxHeight on CachedNetworkImageProvider require ImageCacheManager;
  // [reportImagesCache] is a plain CacheManager. Use ResizeImage for decode caps
  // (same approach as map pins in site_image_provider.dart).
  return ResizeImage.resizeIfNeeded(maxWidth, maxHeight, base);
}
