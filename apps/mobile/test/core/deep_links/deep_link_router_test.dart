import 'package:flutter_test/flutter_test.dart';
import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';

void main() {
  group('DeepLinkRouter.parse', () {
    test('parses /app/events/detail/:id', () {
      final Uri u = Uri.parse('https://chisto.mk/app/events/detail/evt-42');
      final DeepLinkRoute? r = DeepLinkRouter.parse(u);
      expect(r, isA<DeepLinkEventDetail>());
      expect((r as DeepLinkEventDetail).eventId, 'evt-42');
    });

    test('parses events/detail with query eventId', () {
      final Uri u = Uri.parse('chisto://app/events/detail?eventId=evt-9');
      final DeepLinkRoute? r = DeepLinkRouter.parse(u);
      expect(r, isA<DeepLinkEventDetail>());
      expect((r as DeepLinkEventDetail).eventId, 'evt-9');
    });

    test('parses reports/new', () {
      final Uri u = Uri.parse('chisto://app/reports/new');
      expect(DeepLinkRouter.parse(u), isA<DeepLinkNewReport>());
    });

    test('parses home/map-focus with siteId query', () {
      final Uri u = Uri.parse('https://chisto.mk/app/home/map-focus?siteId=site-1');
      final DeepLinkRoute? r = DeepLinkRouter.parse(u);
      expect(r, isA<DeepLinkHomeMapFocus>());
      expect((r as DeepLinkHomeMapFocus).siteId, 'site-1');
    });

    test('parses home?tab=events', () {
      final Uri u = Uri.parse('https://chisto.mk/app/home?tab=events');
      expect(DeepLinkRouter.parse(u), isA<DeepLinkHomeEvents>());
    });

    test('returns null for unknown paths', () {
      expect(DeepLinkRouter.parse(Uri.parse('https://chisto.mk/app/unknown')), isNull);
    });
  });
}
