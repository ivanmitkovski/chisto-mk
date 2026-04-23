import 'package:chisto_mobile/features/events/data/event_impact_receipt_json.dart';
import 'package:chisto_mobile/features/events/domain/models/event_impact_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('eventImpactReceiptFromJson maps completeness and metrics', () {
    final EventImpactReceipt r = eventImpactReceiptFromJson(<String, dynamic>{
      'eventId': 'e1',
      'title': 'Cleanup',
      'siteLabel': 'Park',
      'scheduledAt': '2026-06-01T08:00:00.000Z',
      'endAt': '2026-06-01T10:00:00.000Z',
      'lifecycleStatus': 'completed',
      'participantCount': 5,
      'checkedInCount': 3,
      'reportedBagsCollected': 7,
      'bagsUpdatedAt': '2026-06-01T11:00:00.000Z',
      'evidence': <dynamic>[
        <String, dynamic>{
          'id': 'p1',
          'kind': 'after',
          'imageUrl': 'https://example.com/a.jpg',
          'caption': null,
          'createdAt': '2026-06-01T10:30:00.000Z',
        },
      ],
      'afterImageUrls': <String>['https://example.com/b.jpg'],
      'completeness': 'full',
      'asOf': '2026-06-01T12:00:00.000Z',
      'organizerName': 'A B',
    });

    expect(r.eventId, 'e1');
    expect(r.completeness, EventImpactReceiptCompleteness.full);
    expect(r.checkedInCount, 3);
    expect(r.reportedBagsCollected, 7);
    expect(r.evidence, hasLength(1));
    expect(r.afterImageUrls, hasLength(1));
  });
}
