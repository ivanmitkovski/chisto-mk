import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:chisto_mobile/core/cache/site_images_cache.dart'
    show stableCacheKeyForSiteImage;

/// Disk cache for user avatar URLs (presigned S3; stable key strips volatile query).
final CacheManager userAvatarsCache = CacheManager(
  Config(
    'chisto_user_avatars',
    stalePeriod: const Duration(days: 14),
    maxNrOfCacheObjects: 200,
    fileService: HttpFileService(),
  ),
);

/// Stable lookup key for [CachedNetworkImage] when [url] is HTTPS.
String? stableCacheKeyForUserAvatar(String url) {
  final String trimmed = url.trim();
  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    return null;
  }
  return stableCacheKeyForSiteImage(trimmed);
}
