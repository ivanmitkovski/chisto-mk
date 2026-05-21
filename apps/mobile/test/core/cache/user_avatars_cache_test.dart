import 'package:chisto_mobile/core/cache/user_avatars_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stableCacheKeyForUserAvatar strips volatile presign query', () {
    const String url =
        'https://bucket.s3.eu-central-1.amazonaws.com/avatars/u1.jpg?X-Amz-Signature=abc&X-Amz-Date=20260520';
    final String? key = stableCacheKeyForUserAvatar(url);
    expect(key, isNotNull);
    expect(key, isNot(contains('X-Amz-Signature')));
    expect(key, contains('avatars/u1.jpg'));
  });

  test('stableCacheKeyForUserAvatar returns null for non-http urls', () {
    expect(stableCacheKeyForUserAvatar('/local/path.jpg'), isNull);
  });
}
