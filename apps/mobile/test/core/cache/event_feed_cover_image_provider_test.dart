import 'package:cached_network_image/cached_network_image.dart';
import 'package:chisto_infrastructure/core/cache/site_image_provider.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await ensureWidgetTestPlumbing();
  });

  test('imageProviderForEventFeedCover memoizes by full URL', () {
    const String url =
        'https://cdn.example.com/sites/a.jpg?X-Amz-Signature=one';

    final ImageProvider first = imageProviderForEventFeedCover(url);
    final ImageProvider second = imageProviderForEventFeedCover(url);

    expect(identical(first, second), isTrue);
    expect(first, isA<ResizeImage>());
  });

  test('imageProviderForEventFeedCover uses new provider when URL changes', () {
    const String urlA =
        'https://cdn.example.com/sites/a.jpg?X-Amz-Signature=one';
    const String urlB =
        'https://cdn.example.com/sites/a.jpg?X-Amz-Signature=two';

    final ImageProvider a = imageProviderForEventFeedCover(urlA);
    final ImageProvider b = imageProviderForEventFeedCover(urlB);

    expect(identical(a, b), isFalse);
  });

  test(
    'imageProviderForEventCover wraps HTTPS in CachedNetworkImageProvider',
    () {
      const String url = 'https://cdn.example.com/sites/a.jpg';

      final ImageProvider provider = imageProviderForEventCover(url);

      expect(provider, isA<CachedNetworkImageProvider>());
    },
  );
}
