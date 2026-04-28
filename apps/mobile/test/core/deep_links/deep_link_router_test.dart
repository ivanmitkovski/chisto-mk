import 'package:flutter_test/flutter_test.dart';
import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';

const String _kEventUuid = '550e8400-e29b-41d4-a716-446655440000';
const String _kSiteCuid = 'c1234567890abcdefghijklmn';

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

    group('site deep links (/sites/<id>)', () {
      test('parses HTTPS /sites/:id share path on trusted host', () {
        final Uri u = Uri.parse('https://chisto.mk/sites/$_kSiteCuid?st=token123&cid=cid123');
        final DeepLinkRoute? r = DeepLinkRouter.parse(u);
        expect(r, isA<DeepLinkSiteDetail>());
        expect((r as DeepLinkSiteDetail).siteId, _kSiteCuid);
        expect(r.shareToken, 'token123');
        expect(r.cid, 'cid123');
      });

      test('parses HTTPS /sites/:id on www.chisto.mk', () {
        final Uri u = Uri.parse('https://www.chisto.mk/sites/$_kSiteCuid');
        final DeepLinkRoute? r = DeepLinkRouter.parse(u);
        expect(r, isA<DeepLinkSiteDetail>());
        expect((r as DeepLinkSiteDetail).siteId, _kSiteCuid);
      });

      test('rejects /sites/:id on untrusted host', () {
        final Uri u = Uri.parse('https://evil.example/sites/$_kSiteCuid');
        expect(DeepLinkRouter.parse(u), isNull);
      });

      test('rejects /sites/ path without valid CUID', () {
        final Uri u = Uri.parse('https://chisto.mk/sites/not-a-uuid');
        expect(DeepLinkRouter.parse(u), isNull);
      });

      test('rejects /sites/ path with empty segment', () {
        final Uri u = Uri.parse('https://chisto.mk/sites/');
        expect(DeepLinkRouter.parse(u), isNull);
      });
    });
  });
}
