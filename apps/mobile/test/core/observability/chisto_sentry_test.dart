import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chistoRedactPhotoPathForBreadcrumb', () {
    test('returns empty for null or empty', () {
      expect(chistoRedactPhotoPathForBreadcrumb(null), '');
      expect(chistoRedactPhotoPathForBreadcrumb(''), '');
    });

    test('keeps basename for posix and Windows-style paths', () {
      expect(
        chistoRedactPhotoPathForBreadcrumb('/var/mobile/Containers/Data/photo.jpg'),
        'photo.jpg',
      );
      expect(
        chistoRedactPhotoPathForBreadcrumb(r'C:\Users\me\draft\001.png'),
        '001.png',
      );
      expect(chistoRedactPhotoPathForBreadcrumb('relative-only.webp'), 'relative-only.webp');
    });
  });
}
