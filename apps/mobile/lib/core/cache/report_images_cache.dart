import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'package:chisto_mobile/core/cache/site_images_cache.dart';

/// Same keying as [stableCacheKeyForSiteImage]: `host + path` with volatile
/// presign query stripped. Path-only keys broke lookups (ambiguous vs other
/// hosts and weaker disk keys than the site-media path).
String stableCacheKeyForReportImage(String url) => stableCacheKeyForSiteImage(url);

final CacheManager reportImagesCache = CacheManager(
  Config(
    'chisto_report_images',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 150,
    fileService: HttpFileService(),
  ),
);

const int _heavyCacheBytesThreshold = 250 * 1024 * 1024;

/// If the app cache directory is very large, clear report image disk cache once.
Future<void> maybeEvictReportImagesDiskCacheIfHeavy() async {
  try {
    final Directory root = await getApplicationCacheDirectory();
    final int total = await _shallowCacheDirectoryBytes(root);
    if (total > _heavyCacheBytesThreshold) {
      await reportImagesCache.emptyCache();
    }
  } catch (_) {
    // Best-effort at cold start.
  }
}

/// Fast shallow estimate (root + one directory level) to avoid long cold-start walks.
Future<int> _shallowCacheDirectoryBytes(Directory root) async {
  int sum = 0;
  await for (final FileSystemEntity entity in root.list(
    recursive: false,
    followLinks: false,
  )) {
    if (entity is File) {
      try {
        sum += await entity.length();
      } catch (_) {
        // Ignore.
      }
    } else if (entity is Directory) {
      await for (final FileSystemEntity inner in entity.list(
        recursive: false,
        followLinks: false,
      )) {
        if (inner is File) {
          try {
            sum += await inner.length();
          } catch (_) {
            // Ignore.
          }
        }
      }
    }
  }
  return sum;
}
