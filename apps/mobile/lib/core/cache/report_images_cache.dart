import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Stable cache key for report images. S3 presigned URLs change on each API
/// call (new signature/expiry); the path (object key) is stable.
String stableCacheKeyForReportImage(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) return url;
  return uri.path.isNotEmpty ? uri.path : url;
}

final CacheManager reportImagesCache = CacheManager(
  Config(
    'chisto_report_images',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 200,
  ),
);
