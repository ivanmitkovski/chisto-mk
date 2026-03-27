import 'package:chisto_mobile/core/cache/site_images_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'stableCacheKeyForSiteImage strips volatile query params from signed URL',
    () {
      const url =
          'https://example-bucket.s3.eu-central-1.amazonaws.com/reports/a1/b2.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=abc';

      final key = stableCacheKeyForSiteImage(url);

      expect(
        key,
        'example-bucket.s3.eu-central-1.amazonaws.com/reports/a1/b2.jpg',
      );
    },
  );

  test('stableCacheKeyForSiteImage keeps identity version params', () {
    const url =
        'https://cdn.example.com/site-images/a1.jpg?v=42&X-Amz-Expires=1200&X-Amz-Signature=abc';

    final key = stableCacheKeyForSiteImage(url);

    expect(key, 'cdn.example.com/site-images/a1.jpg?v=42');
  });

  test('stableCacheKeyForSiteImage falls back to original for invalid URL', () {
    const raw = 'not-a-url';

    final key = stableCacheKeyForSiteImage(raw);

    expect(key, raw);
  });
}
