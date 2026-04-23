import 'package:flutter_test/flutter_test.dart';
import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';

const String _kEventUuid = '550e8400-e29b-41d4-a716-446655440000';

void main() {
  group('DeepLinkRouter.parse', () {
    test('parses /app/events/detail/:id', () {
      final Uri u = Uri.parse('https://chisto.mk/app/events/detail/$_kEventUuid');
      final DeepLinkRoute? r = DeepLinkRouter.parse(u);
      expect(r, isA<DeepLinkEventDetail>());
      expect((r as DeepLinkEventDetail).eventId, _kEventUuid);
    });

    test('parses HTTPS /events/:id share path on trusted host', () {
      final Uri u = Uri.parse('https://chisto.mk/events/$_kEventUuid');
      final DeepLinkRoute? r = DeepLinkRouter.parse(u);
      expect(r, isA<DeepLinkEventDetail>());
      expect((r as DeepLinkEventDetail).eventId, _kEventUuid);
    });

    test('rejects /events/:id on untrusted host', () {
      final Uri u = Uri.parse('https://evil.example/events/$_kEventUuid');
      expect(DeepLinkRouter.parse(u), isNull);
    });

    test('parses events/detail with query eventId', () {
      final Uri u = Uri.parse('chisto://app/events/detail?eventId=$_kEventUuid');
      final DeepLinkRoute? r = DeepLinkRouter.parse(u);
      expect(r, isA<DeepLinkEventDetail>());
      expect((r as DeepLinkEventDetail).eventId, _kEventUuid);
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
