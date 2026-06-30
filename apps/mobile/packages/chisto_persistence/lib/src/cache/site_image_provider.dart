import 'dart:collection';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chisto_persistence/src/cache/site_images_cache.dart';
import 'package:flutter/material.dart';

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

/// Decode cap for events feed list thumbnails ([AppSpacing.eventsCardThumbnailSize] at 3x).
const int kEventFeedCoverDecodeMaxPx = 256;

final LinkedHashMap<String, ImageProvider> _eventFeedCoverProviders =
    LinkedHashMap<String, ImageProvider>();

bool _isNetworkUrl(String value) =>
    value.startsWith('http://') || value.startsWith('https://');

/// Memoized cover provider for the events feed and [EcoEventCoverImage] warm-up.
///
/// Uses the same disk cache as site media ([siteImagesCache]) with a signature-
/// stable [cacheKey], so presigned URL rotation does not force a full re-download.
/// The memo key is the full URL so a freshly signed URL can still load when needed.
ImageProvider imageProviderForEventFeedCover(String httpsUrl) {
  final ImageProvider? hit = _eventFeedCoverProviders.remove(httpsUrl);
  if (hit != null) {
    _eventFeedCoverProviders[httpsUrl] = hit;
    return hit;
  }
  while (_eventFeedCoverProviders.length >= 200) {
    _eventFeedCoverProviders.remove(_eventFeedCoverProviders.keys.first);
  }
  final String diskKey = stableCacheKeyForSiteImage(httpsUrl);
  final ImageProvider created = ResizeImage(
    CachedNetworkImageProvider(
      httpsUrl,
      cacheManager: siteImagesCache,
      cacheKey: diskKey,
    ),
    width: kEventFeedCoverDecodeMaxPx,
    height: kEventFeedCoverDecodeMaxPx,
    allowUpscaling: false,
  );
  _eventFeedCoverProviders[httpsUrl] = created;
  return created;
}

/// Network cover for event detail / evidence at full decode width when known.
ImageProvider imageProviderForEventCover(
  String pathOrUrl, {
  int? maxWidth,
  int? maxHeight,
}) {
  if (!_isNetworkUrl(pathOrUrl)) {
    return FileImage(File(pathOrUrl));
  }
  return CachedNetworkImageProvider(
    pathOrUrl,
    cacheManager: siteImagesCache,
    cacheKey: stableCacheKeyForSiteImage(pathOrUrl),
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );
}
