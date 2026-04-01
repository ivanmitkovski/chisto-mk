import 'package:chisto_mobile/features/profile/data/points_history_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pointsHistoryFromJson', () {
    test('parses items, milestones, and nextCursor', () {
      final result = pointsHistoryFromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'tx1',
            'createdAt': '2026-01-15T10:00:00.000Z',
            'delta': 25,
            'reasonCode': 'FIRST_REPORT',
            'referenceType': 'Report',
            'referenceId': 'r1',
          },
        ],
        'meta': <String, dynamic>{
          'milestones': <Map<String, dynamic>>[
            <String, dynamic>{
              'reachedAt': '2026-01-15T10:00:00.000Z',
              'level': 2,
              'levelTierKey': 'numeric_2',
              'levelDisplayName': 'Level 2',
            },
          ],
          'nextCursor': 'abc',
        },
      });

      expect(result.items.length, 1);
      expect(result.items.first.id, 'tx1');
      expect(result.items.first.delta, 25);
      expect(result.items.first.reasonCode, 'FIRST_REPORT');
      expect(result.milestones.length, 1);
      expect(result.milestones.first.level, 2);
      expect(result.nextCursor, 'abc');
    });

    test('tolerates missing meta and data', () {
      final result = pointsHistoryFromJson(<String, dynamic>{});
      expect(result.items, isEmpty);
      expect(result.milestones, isEmpty);
      expect(result.nextCursor, isNull);
    });
  });
}
