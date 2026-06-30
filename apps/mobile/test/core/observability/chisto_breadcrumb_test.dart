import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chistoRedactPhotoPathForBreadcrumb keeps basename only', () {
    expect(
      chistoRedactPhotoPathForBreadcrumb(
        '/var/mobile/Containers/foo/photo.jpg',
      ),
      'photo.jpg',
    );
  });

  test('chistoBreadcrumb does not throw when Sentry unavailable', () {
    expect(
      () => chistoBreadcrumb(category: 'test', message: 'smoke'),
      returnsNormally,
    );
  });
}
