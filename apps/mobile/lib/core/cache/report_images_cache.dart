import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:chisto_mobile/core/cache/site_images_cache.dart';

/// Same keying as [stableCacheKeyForSiteImage]: `host + path` with volatile
/// presign query stripped. Path-only keys broke lookups (ambiguous vs other
/// hosts and weaker disk keys than the site-media path).
String stableCacheKeyForReportImage(String url) => stableCacheKeyForSiteImage(url);

final CacheManager reportImagesCache = CacheManager(
  Config(
    'chisto_report_images',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 200,
    fileService: HttpFileService(),
  ),
);
