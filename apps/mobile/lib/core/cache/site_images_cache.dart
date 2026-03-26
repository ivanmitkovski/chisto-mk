import 'package:flutter_cache_manager/flutter_cache_manager.dart';

String stableCacheKeyForSiteImage(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) return url;
  return uri.path.isNotEmpty ? uri.path : url;
}

final CacheManager siteImagesCache = CacheManager(
  Config(
    'chisto_site_images',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 300,
  ),
);
