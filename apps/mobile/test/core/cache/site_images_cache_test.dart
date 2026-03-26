import 'package:chisto_mobile/core/cache/site_images_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stableCacheKeyForSiteImage strips query params from presigned URL', () {
    const url =
        'https://example-bucket.s3.eu-central-1.amazonaws.com/reports/a1/b2.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=abc';

    final key = stableCacheKeyForSiteImage(url);

    expect(key, '/reports/a1/b2.jpg');
  });

  test('stableCacheKeyForSiteImage falls back to original for invalid URL', () {
    const raw = 'not-a-url';

    final key = stableCacheKeyForSiteImage(raw);

    expect(key, raw);
  });
}
