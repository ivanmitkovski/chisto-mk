import 'package:feature_events/src/domain/models/event_pulse_route_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventRouteSegmentModel.fromJson', () {
    test('parses full segment payload', () {
      final EventRouteSegmentModel segment =
          EventRouteSegmentModel.fromJson(const <String, dynamic>{
            'id': 'seg-1',
            'sortOrder': 2,
            'label': 'North bank',
            'latitude': 41.9973,
            'longitude': 21.428,
            'status': 'completed',
            'claimedByUserId': 'user-1',
            'claimedAt': '2026-03-27T10:00:00.000Z',
            'completedAt': '2026-03-27T11:30:00.000Z',
          });

      expect(segment.id, 'seg-1');
      expect(segment.sortOrder, 2);
      expect(segment.label, 'North bank');
      expect(segment.latitude, closeTo(41.9973, 0.0001));
      expect(segment.longitude, closeTo(21.428, 0.0001));
      expect(segment.status, 'completed');
      expect(segment.claimedByUserId, 'user-1');
      expect(segment.claimedAt, DateTime.parse('2026-03-27T10:00:00.000Z'));
      expect(segment.completedAt, DateTime.parse('2026-03-27T11:30:00.000Z'));
      expect(segment.isCompleted, isTrue);
    });

    test('applies defaults for missing fields', () {
      final EventRouteSegmentModel segment = EventRouteSegmentModel.fromJson(
        const <String, dynamic>{},
      );

      expect(segment.id, '');
      expect(segment.sortOrder, 0);
      expect(segment.latitude, 0);
      expect(segment.longitude, 0);
      expect(segment.status, 'open');
      expect(segment.label, isNull);
      expect(segment.claimedByUserId, isNull);
      expect(segment.claimedAt, isNull);
      expect(segment.completedAt, isNull);
      expect(segment.isCompleted, isFalse);
    });
  });

  group('EventRouteSegmentModel equality', () {
    test('value equality includes all fields', () {
      const EventRouteSegmentModel a = EventRouteSegmentModel(
        id: 'seg-1',
        sortOrder: 1,
        latitude: 41,
        longitude: 21,
        status: 'open',
        label: 'A',
      );
      const EventRouteSegmentModel b = EventRouteSegmentModel(
        id: 'seg-1',
        sortOrder: 1,
        latitude: 41,
        longitude: 21,
        status: 'open',
        label: 'A',
      );
      const EventRouteSegmentModel c = EventRouteSegmentModel(
        id: 'seg-2',
        sortOrder: 1,
        latitude: 41,
        longitude: 21,
        status: 'open',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('EventEvidenceStripItem.fromJson', () {
    test('parses evidence item payload', () {
      final EventEvidenceStripItem item =
          EventEvidenceStripItem.fromJson(const <String, dynamic>{
            'id': 'ev-1',
            'kind': 'before',
            'imageUrl': 'https://cdn.example.com/before.jpg',
            'caption': 'Before cleanup',
            'createdAt': '2026-03-27T12:00:00.000Z',
          });

      expect(item.id, 'ev-1');
      expect(item.kind, 'before');
      expect(item.imageUrl, 'https://cdn.example.com/before.jpg');
      expect(item.caption, 'Before cleanup');
      expect(item.createdAt, DateTime.parse('2026-03-27T12:00:00.000Z'));
    });

    test('table-driven: defaults for sparse json', () {
      final EventEvidenceStripItem item = EventEvidenceStripItem.fromJson(
        const <String, dynamic>{'createdAt': '2026-03-27T12:00:00.000Z'},
      );

      expect(item.id, '');
      expect(item.kind, 'field');
      expect(item.imageUrl, '');
      expect(item.caption, isNull);
    });
  });

  group('EventEvidenceStripItem equality', () {
    test('value equality includes all fields', () {
      final DateTime createdAt = DateTime.utc(2026, 3, 27, 12);
      final EventEvidenceStripItem a = EventEvidenceStripItem(
        id: 'ev-1',
        kind: 'after',
        imageUrl: 'https://cdn/a.jpg',
        caption: 'Done',
        createdAt: createdAt,
      );
      final EventEvidenceStripItem b = EventEvidenceStripItem(
        id: 'ev-1',
        kind: 'after',
        imageUrl: 'https://cdn/a.jpg',
        caption: 'Done',
        createdAt: createdAt,
      );
      final EventEvidenceStripItem c = EventEvidenceStripItem(
        id: 'ev-2',
        kind: 'after',
        imageUrl: 'https://cdn/a.jpg',
        createdAt: createdAt,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
