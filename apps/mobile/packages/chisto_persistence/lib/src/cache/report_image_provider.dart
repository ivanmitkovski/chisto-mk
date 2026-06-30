import 'dart:collection';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chisto_persistence/src/cache/report_images_cache.dart'
    show reportImagesCache, stableCacheKeyForReportImage;
import 'package:flutter/material.dart';

const int kReportEvidenceFeedMaxDecodeWidth = 1280;

/// Width cap for full-width evidence (detail sheet, prefetch).
int reportEvidenceDecodeWidthCap(BuildContext context) {
  final MediaQueryData mq = MediaQuery.of(context);
  final double px = mq.size.width * mq.devicePixelRatio;
  return px.clamp(1, kReportEvidenceFeedMaxDecodeWidth).round();
}

final LinkedHashMap<String, ImageProvider> _reportEvidenceProviders =
    LinkedHashMap<String, ImageProvider>();

/// Memoization key for the [ImageProvider] instance.
///
/// IMPORTANT: network URLs are keyed by their **full** value (signature included).
/// Report media is served via short-lived S3 presigned URLs; keying by a
/// signature-stripped identity would pin the provider to the first (eventually
/// expired) URL forever, so a freshly-signed URL could never heal a failed load.
/// Disk reuse still de-dupes bytes across signatures via the stable [cacheKey]
/// passed to [CachedNetworkImageProvider], so a fresh URL avoids a re-download
/// whenever the object is already cached on disk.
String _providerCacheKey(String pathOrUrl, int? maxWidth, int? maxHeight) {
  return '$pathOrUrl|w:${maxWidth ?? 0}|h:${maxHeight ?? 0}';
}

bool _isNetworkUrl(String s) =>
    s.startsWith('http://') || s.startsWith('https://');

/// Memoized [ImageProvider] for report evidence (list thumbs, detail gallery, prefetch).
///
/// Instances are memoized per (URL, decode size) so rebuilds, precache, and
/// [AppSmartImage] share the same decode path. The underlying disk cache is keyed
/// by a signature-stripped key so the same object is downloaded at most once even
/// as presigned signatures rotate.
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

  final ImageProvider<Object> base = _isNetworkUrl(pathOrUrl)
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
