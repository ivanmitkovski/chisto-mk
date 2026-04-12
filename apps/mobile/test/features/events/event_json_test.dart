import 'package:chisto_mobile/features/events/data/event_json.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ecoEventFromJson', () {
    test('maps scheduledAt/endAt into date and time fields', () {
      final EcoEvent event = ecoEventFromJson(<String, dynamic>{
        'id': 'evt-1',
        'title': 'T',
        'description': 'D',
        'category': 'riverAndLake',
        'siteId': 's1',
        'siteName': 'River',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'scheduledAt': '2026-08-15T09:30:00.000Z',
        'endAt': '2026-08-15T11:45:00.000Z',
        'status': 'upcoming',
        'participantCount': 3,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'gear': <String>['trashBags'],
        'scale': 'medium',
        'difficulty': 'easy',
      });

      expect(event.id, 'evt-1');
      expect(event.category, EcoEventCategory.riverAndLake);
      expect(
        event.endTime.totalMinutes > event.startTime.totalMinutes,
        isTrue,
      );
      expect(event.status, EcoEventStatus.upcoming);
      expect(event.gear, contains(EventGear.trashBags));
      expect(event.scale, CleanupScale.medium);
      expect(event.difficulty, EventDifficulty.easy);
    });

    test('maps moderation and check-in flags used by detail + check-in flows', () {
      final EcoEvent event = ecoEventFromJson(<String, dynamic>{
        'id': 'evt-mod',
        'title': 'T',
        'description': 'D',
        'category': 'generalCleanup',
        'siteId': 's1',
        'siteName': 'Site',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'scheduledAt': '2026-08-15T09:30:00.000Z',
        'endAt': '2026-08-15T11:45:00.000Z',
        'status': 'upcoming',
        'participantCount': 0,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'moderationApproved': false,
        'isCheckInOpen': true,
        'checkedInCount': 2,
        'activeCheckInSessionId': 'sess-1',
        'attendeeCheckInStatus': 'checkedIn',
      });

      expect(event.moderationApproved, isFalse);
      expect(event.isCheckInOpen, isTrue);
      expect(event.checkedInCount, 2);
      expect(event.activeCheckInSessionId, 'sess-1');
      expect(event.attendeeCheckInStatus, AttendeeCheckInStatus.checkedIn);
    });
  });

  group('parsePointsAwardedFromJson', () {
    test('reads int and num', () {
      expect(parsePointsAwardedFromJson(<String, dynamic>{'pointsAwarded': 12}), 12);
      expect(parsePointsAwardedFromJson(<String, dynamic>{'pointsAwarded': 15.0}), 15);
    });

    test('returns 0 when absent or invalid', () {
      expect(parsePointsAwardedFromJson(null), 0);
      expect(parsePointsAwardedFromJson(<String, dynamic>{}), 0);
      expect(
        parsePointsAwardedFromJson(<String, dynamic>{'pointsAwarded': 'x'}),
        0,
      );
    });
  });
}
