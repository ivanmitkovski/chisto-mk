import 'package:chisto_infrastructure/core/deep_links/deep_link_router.dart';
import 'package:chisto_infrastructure/core/deep_links/share_token_from_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shareTokenFromDeepLinkRoute extracts site detail token', () {
    const DeepLinkRoute route = DeepLinkSiteDetail(
      'site_abc',
      shareToken: 'tok_site',
    );
    expect(shareTokenFromDeepLinkRoute(route), 'tok_site');
  });

  test('shareTokenFromDeepLinkRoute extracts map focus token', () {
    const DeepLinkRoute route = DeepLinkHomeMapFocus(
      'site_abc',
      shareToken: 'tok_map',
    );
    expect(shareTokenFromDeepLinkRoute(route), 'tok_map');
  });

  test('shareTokenFromDeepLinkRoute returns null for routes without token', () {
    const DeepLinkRoute route = DeepLinkEventDetail('evt_1');
    expect(shareTokenFromDeepLinkRoute(route), isNull);
  });
}
