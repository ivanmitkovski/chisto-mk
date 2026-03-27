import 'package:flutter_cache_manager/flutter_cache_manager.dart';

const Duration kSiteImageCacheStalePeriod = Duration(days: 21);
const int kSiteImageCacheMaxObjects = 450;

const Set<String> _volatileSignedQueryKeys = <String>{
  'x-amz-algorithm',
  'x-amz-credential',
  'x-amz-date',
  'x-amz-expires',
  'x-amz-security-token',
  'x-amz-signature',
  'x-amz-signedheaders',
  'x-goog-algorithm',
  'x-goog-credential',
  'x-goog-date',
  'x-goog-expires',
  'x-goog-signature',
  'x-goog-signedheaders',
  'expires',
  'signature',
  'token',
};

const Set<String> _identityQueryKeys = <String>{
  'v',
  'version',
  'rev',
  'hash',
  'etag',
};

String stableCacheKeyForSiteImage(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) return url;
  if (uri.path.isEmpty) return url;

  final Map<String, String> normalizedIdentityParams = <String, String>{};
  final List<String> keys = uri.queryParametersAll.keys.toList()..sort();
  for (final String rawKey in keys) {
    final String key = rawKey.toLowerCase();
    if (_volatileSignedQueryKeys.contains(key)) continue;
    if (!_identityQueryKeys.contains(key)) continue;
    final List<String> values =
        uri.queryParametersAll[rawKey] ?? const <String>[];
    if (values.isEmpty) continue;
    normalizedIdentityParams[key] = values.last;
  }

  final String identity = normalizedIdentityParams.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join('&');
  final String hostPath = '${uri.host}${uri.path}';
  return identity.isEmpty ? hostPath : '$hostPath?$identity';
}

final CacheManager siteImagesCache = CacheManager(
  Config(
    'chisto_site_images',
    stalePeriod: kSiteImageCacheStalePeriod,
    maxNrOfCacheObjects: kSiteImageCacheMaxObjects,
    fileService: HttpFileService(),
  ),
);
