import 'dart:collection';
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

/// Decode size cap for circular map pins (~48 logical px at 3x + border).
const int kMapPinImageDecodeMaxPx = 256;

final LinkedHashMap<String, ImageProvider> _mapPinImageProviders =
    LinkedHashMap<String, ImageProvider>();

ImageProvider imageProviderForMapPin(String httpsUrl) {
  // Memoize by full URL so new presigned query strings get a new provider after map refresh.
  final String diskKey = stableCacheKeyForSiteImage(httpsUrl);
  final ImageProvider? hit = _mapPinImageProviders.remove(httpsUrl);
  if (hit != null) {
    _mapPinImageProviders[httpsUrl] = hit;
    return hit;
  }
  while (_mapPinImageProviders.length >= 320) {
    _mapPinImageProviders.remove(_mapPinImageProviders.keys.first);
  }
  // maxWidth/maxHeight on CachedNetworkImageProvider require ImageCacheManager;
  // siteImagesCache is a plain CacheManager. ResizeImage caps decode size instead.
  final ImageProvider created = ResizeImage(
    CachedNetworkImageProvider(
      httpsUrl,
      cacheManager: siteImagesCache,
      cacheKey: diskKey,
    ),
    width: kMapPinImageDecodeMaxPx,
    height: kMapPinImageDecodeMaxPx,
    allowUpscaling: false,
  );
  _mapPinImageProviders[httpsUrl] = created;
  return created;
}
