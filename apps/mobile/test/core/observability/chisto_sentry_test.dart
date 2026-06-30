import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('chistoSentryBeforeSend', () {
    test('filters Authorization header and token query params', () {
      final SentryEvent event = SentryEvent(
        request: SentryRequest(
          url: 'https://api.chisto.mk/auth/reset?token=secret',
          headers: <String, String>{'Authorization': 'Bearer abc'},
          data: <String, String>{'password': 'secret'},
          cookies: 'session=abc',
        ),
      );
      final SentryEvent? out = chistoSentryBeforeSend(event, Hint());
      expect(out, isNotNull);
      expect(out!.request!.headers['Authorization'], '[Filtered]');
      expect(out.request!.url ?? '', isNot(contains('secret')));
      expect(out.request!.data, '[Filtered]');
      expect(out.request!.cookies, '[Filtered]');
    });
  });

  group('chistoRedactPhotoPathForBreadcrumb', () {
    test('returns empty for null or empty', () {
      expect(chistoRedactPhotoPathForBreadcrumb(null), '');
      expect(chistoRedactPhotoPathForBreadcrumb(''), '');
    });

    test('keeps basename for posix and Windows-style paths', () {
      expect(
        chistoRedactPhotoPathForBreadcrumb(
          '/var/mobile/Containers/Data/photo.jpg',
        ),
        'photo.jpg',
      );
      expect(
        chistoRedactPhotoPathForBreadcrumb(r'C:\Users\me\draft\001.png'),
        '001.png',
      );
      expect(
        chistoRedactPhotoPathForBreadcrumb('relative-only.webp'),
        'relative-only.webp',
      );
    });
  });
}
