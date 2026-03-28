import 'package:chisto_mobile/features/home/data/map_realtime/map_site_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapSiteEvent.tryFromJson', () {
    test('parses a valid site update payload', () {
      final MapSiteEvent? event = MapSiteEvent.tryFromJson(<String, dynamic>{
        'eventId': 'site-1:123:site_updated',
        'type': 'site_updated',
        'siteId': 'site-1',
        'occurredAtMs': 1_700_000_000_000,
        'updatedAt': '2026-03-27T12:00:00.000Z',
        'mutation': <String, dynamic>{
          'kind': 'status_changed',
          'status': 'VERIFIED',
          'latitude': 41.9973,
          'longitude': 21.428,
        },
      });

      expect(event, isNotNull);
      expect(event!.siteId, 'site-1');
      expect(event.mutationKind, 'status_changed');
      expect(event.status, 'VERIFIED');
      expect(event.latitude, closeTo(41.9973, 0.0001));
      expect(event.longitude, closeTo(21.428, 0.0001));
    });

    test('returns null for incomplete payload', () {
      final MapSiteEvent? event = MapSiteEvent.tryFromJson(<String, dynamic>{
        'type': 'site_updated',
        'siteId': 'site-1',
      });

      expect(event, isNull);
    });
  });
}
