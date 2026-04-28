import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';
import 'package:chisto_mobile/core/deep_links/share_token_from_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shareTokenFromDeepLinkRoute', () {
    test('returns token for site detail deep link', () {
      const route = DeepLinkSiteDetail(
        'c1234567890abcdefghijklmn',
        shareToken: 'tok_1',
      );
      expect(shareTokenFromDeepLinkRoute(route), 'tok_1');
    });

    test('returns token for map-focus deep link', () {
      const route = DeepLinkHomeMapFocus(
        'c1234567890abcdefghijklmn',
        shareToken: 'tok_2',
      );
      expect(shareTokenFromDeepLinkRoute(route), 'tok_2');
    });

    test('returns null when route has no token', () {
      const route = DeepLinkNewReport();
      expect(shareTokenFromDeepLinkRoute(route), isNull);
    });
  });
}
