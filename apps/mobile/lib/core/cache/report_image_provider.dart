import 'dart:collection';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/cache/report_images_cache.dart'
    show reportImagesCache, stableCacheKeyForReportImage;

const int kReportEvidenceFeedMaxDecodeWidth = 1280;

/// Width cap for full-width evidence (detail sheet, prefetch).
int reportEvidenceDecodeWidthCap(BuildContext context) {
  final MediaQueryData mq = MediaQuery.of(context);
  final double px = mq.size.width * mq.devicePixelRatio;
  return px.clamp(1, kReportEvidenceFeedMaxDecodeWidth).round();
}

final LinkedHashMap<String, ImageProvider> _reportEvidenceProviders =
    LinkedHashMap<String, ImageProvider>();

String _providerCacheKey(String pathOrUrl, int? maxWidth, int? maxHeight) {
  final String identity = pathOrUrl.startsWith('http://') ||
          pathOrUrl.startsWith('https://')
      ? stableCacheKeyForReportImage(pathOrUrl)
      : pathOrUrl;
  return '$identity|w:${maxWidth ?? 0}|h:${maxHeight ?? 0}';
}

/// Stable [ImageProvider] for report evidence (list thumbs, detail gallery, prefetch).
///
/// Instances are memoized so rebuilds, precache, and [AppSmartImage] share the same
/// cache key and decode path.
ImageProvider imageProviderForReportEvidence(
  String pathOrUrl, {
  int? maxWidth,
  int? maxHeight,
}) {
  final String key = _providerCacheKey(pathOrUrl, maxWidth, maxHeight);
  final ImageProvider? hit = _reportEvidenceProviders.remove(key);
  if (hit != null) {
    _reportEvidenceProviders[key] = hit;
    return hit;
  }
  while (_reportEvidenceProviders.length >= 160) {
    _reportEvidenceProviders.remove(_reportEvidenceProviders.keys.first);
  }

  final ImageProvider<Object> base =
      pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')
          ? CachedNetworkImageProvider(
              pathOrUrl,
              cacheManager: reportImagesCache,
              cacheKey: stableCacheKeyForReportImage(pathOrUrl),
            )
          : FileImage(File(pathOrUrl));

  final ImageProvider created = ResizeImage.resizeIfNeeded(
    maxWidth,
    maxHeight,
    base,
  );
  _reportEvidenceProviders[key] = created;
  return created;
}
