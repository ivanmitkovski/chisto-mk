import 'package:feature_reports/src/data/reports_realtime/reports_owner_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportsOwnerEvent.tryFromJson', () {
    test('parses a valid owner report payload', () {
      final ReportsOwnerEvent? event = ReportsOwnerEvent.tryFromJson(
        <String, dynamic>{
          'eventId': 'owner-1:123:report_updated',
          'type': 'report_updated',
          'ownerId': 'owner-1',
          'reportId': 'report-1',
          'occurredAtMs': 1_700_000_000_000,
          'mutation': <String, dynamic>{
            'kind': 'status_changed',
            'status': 'VERIFIED',
          },
        },
      );

      expect(event, isNotNull);
      expect(event!.eventId, 'owner-1:123:report_updated');
      expect(event.type, 'report_updated');
      expect(event.ownerId, 'owner-1');
      expect(event.reportId, 'report-1');
      expect(event.occurredAtMs, 1_700_000_000_000);
      expect(event.mutationKind, 'status_changed');
      expect(event.status, 'VERIFIED');
    });

    test('defaults mutationKind to updated when mutation missing', () {
      final ReportsOwnerEvent? event =
          ReportsOwnerEvent.tryFromJson(<String, dynamic>{
            'eventId': 'e-1',
            'type': 'report_updated',
            'ownerId': 'owner-1',
            'reportId': 'report-1',
            'occurredAtMs': 42,
          });

      expect(event, isNotNull);
      expect(event!.mutationKind, 'updated');
      expect(event.status, isNull);
    });

    test('coerces numeric occurredAtMs', () {
      final ReportsOwnerEvent? event =
          ReportsOwnerEvent.tryFromJson(<String, dynamic>{
            'eventId': 'e-2',
            'type': 'report_updated',
            'ownerId': 'owner-1',
            'reportId': 'report-2',
            'occurredAtMs': 123.9,
          });

      expect(event, isNotNull);
      expect(event!.occurredAtMs, 123);
    });

    test('table-driven: invalid payloads return null', () {
      final List<Map<String, dynamic>> cases = <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'report_updated',
          'ownerId': 'owner-1',
          'reportId': 'report-1',
          'occurredAtMs': 1,
        },
        <String, dynamic>{
          'eventId': 'e-3',
          'type': 'report_updated',
          'ownerId': 'owner-1',
          'reportId': 'report-3',
          'occurredAtMs': 'not-a-number',
        },
        <String, dynamic>{
          'eventId': 1,
          'type': 'report_updated',
          'ownerId': 'owner-1',
          'reportId': 'report-4',
          'occurredAtMs': 1,
        },
      ];
      for (final Map<String, dynamic> json in cases) {
        expect(ReportsOwnerEvent.tryFromJson(json), isNull);
      }
    });

    test('ignores empty mutation kind and status', () {
      final ReportsOwnerEvent? event = ReportsOwnerEvent.tryFromJson(
        <String, dynamic>{
          'eventId': 'e-4',
          'type': 'report_updated',
          'ownerId': 'owner-1',
          'reportId': 'report-5',
          'occurredAtMs': 99,
          'mutation': <String, dynamic>{'kind': '', 'status': ''},
        },
      );

      expect(event, isNotNull);
      expect(event!.mutationKind, 'updated');
      expect(event.status, isNull);
    });
  });
}
