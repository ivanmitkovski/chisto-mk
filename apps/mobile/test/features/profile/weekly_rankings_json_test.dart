import 'package:chisto_mobile/features/profile/data/weekly_rankings_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weeklyRankingsFromJson', () {
    test('parses leaderboard entries', () {
      final result = weeklyRankingsFromJson(<String, dynamic>{
        'weekStartsAt': '2026-03-30T22:00:00.000Z',
        'weekEndsAt': '2026-04-05T21:59:59.999Z',
        'myRank': 5,
        'myWeeklyPoints': 12,
        'entries': <Map<String, dynamic>>[
          <String, dynamic>{
            'rank': 1,
            'userId': 'a',
            'displayName': 'One User',
            'weeklyPoints': 100,
            'isCurrentUser': false,
          },
          <String, dynamic>{
            'rank': 2,
            'userId': 'b',
            'displayName': 'Me User',
            'weeklyPoints': 12,
            'isCurrentUser': true,
          },
        ],
      });

      expect(result.entries.length, 2);
      expect(result.entries[1].isCurrentUser, isTrue);
      expect(result.entries[1].weeklyPoints, 12);
      expect(result.myRank, 5);
      expect(result.myWeeklyPoints, 12);
    });
  });
}
