import 'package:feature_events/src/domain/models/event_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventAnalytics.fromJson', () {
    test(
      'parses joinersCumulative and normalizes check-ins to 24 UTC slots',
      () {
        final EventAnalytics a = EventAnalytics.fromJson(<String, dynamic>{
          'totalJoiners': 2,
          'checkedInCount': 1,
          'attendanceRate': 50,
          'generatedAt': '2026-06-01T15:00:00.000Z',
          'lastJoinAt': '2026-06-01T14:00:00.000Z',
          'lastCheckInAt': '2026-06-01T11:30:00.000Z',
          'joinersCumulative': <dynamic>[
            <String, dynamic>{
              'at': '2026-06-01T10:00:00.000Z',
              'cumulativeJoiners': 1,
            },
            <String, dynamic>{
              'at': '2026-06-01T14:00:00.000Z',
              'cumulativeJoiners': 2,
            },
          ],
          'checkInsByHour': <dynamic>[
            <String, dynamic>{'hour': 11, 'count': 1},
          ],
        });

        expect(a.joinersCumulative, hasLength(2));
        expect(a.joinersCumulative[1].cumulativeJoiners, 2);
        expect(a.checkInsByHour, hasLength(24));
        expect(a.checkInsByHour[11].count, 1);
        expect(a.checkInsByHour[0].count, 0);
        expect(a.generatedAt?.toUtc(), DateTime.utc(2026, 6, 1, 15));
        expect(a.lastJoinAt?.toUtc(), DateTime.utc(2026, 6, 1, 14));
        expect(a.lastCheckInAt?.toUtc(), DateTime.utc(2026, 6, 1, 11, 30));
      },
    );
  });
}
