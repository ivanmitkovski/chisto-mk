import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/cache/site_images_cache.dart';

ImageProvider imageProviderForSiteMedia(
  String pathOrUrl, {
  int? maxWidth,
  int? maxHeight,
}) {
  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    return CachedNetworkImageProvider(
      pathOrUrl,
      cacheManager: siteImagesCache,
      cacheKey: stableCacheKeyForSiteImage(pathOrUrl),
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }
  return FileImage(File(pathOrUrl));
}
