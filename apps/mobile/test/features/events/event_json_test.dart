import 'package:chisto_mobile/features/events/data/event_json.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ecoEventFromJson', () {
    test('returns null when scheduledAt is not a valid ISO 8601 string', () {
      final EcoEvent? event = ecoEventFromJson(<String, dynamic>{
        'id': 'evt-bad-date',
        'title': 'T',
        'description': 'D',
        'category': 'generalCleanup',
        'siteId': 's1',
        'siteName': 'Park',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'scheduledAt': 'not-a-date',
        'status': 'upcoming',
        'participantCount': 0,
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(event, isNull);
    });

    test('tolerates bad endAt by falling back to start + 2h', () {
      final EcoEvent? event = ecoEventFromJson(<String, dynamic>{
        'id': 'evt-bad-end',
        'title': 'T',
        'description': 'D',
        'category': 'generalCleanup',
        'siteId': 's1',
        'siteName': 'Park',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'scheduledAt': '2026-08-15T09:30:00.000Z',
        'endAt': 'garbage',
        'status': 'upcoming',
        'participantCount': 0,
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(event, isNotNull);
      expect(
        event!.endTime.totalMinutes - event.startTime.totalMinutes,
        120,
      );
    });

    test('maps scheduledAt/endAt into date and time fields', () {
      final EcoEvent? event = ecoEventFromJson(<String, dynamic>{
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

      expect(event, isNotNull);
      expect(event!.id, 'evt-1');
      expect(event.category, EcoEventCategory.riverAndLake);
      expect(
        event.endTime.totalMinutes > event.startTime.totalMinutes,
        isTrue,
      );
      expect(event.status, EcoEventStatus.upcoming);
      expect(event.gear, contains(EventGear.trashBags));
      expect(event.scale, CleanupScale.medium);
      expect(event.difficulty, EventDifficulty.easy);
      expect(event.moderationApproved, isFalse);
    });

    test('treats missing moderationApproved as not approved', () {
      final EcoEvent? event = ecoEventFromJson(<String, dynamic>{
        'id': 'evt-no-mod',
        'title': 'T',
        'description': 'D',
        'category': 'generalCleanup',
        'siteId': 's1',
        'siteName': 'Park',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'scheduledAt': '2026-08-15T09:30:00.000Z',
        'status': 'upcoming',
        'participantCount': 0,
        'createdAt': '2026-01-01T00:00:00.000Z',
      });
      expect(event, isNotNull);
      expect(event!.moderationApproved, isFalse);
    });

    test('parses moderationApproved true when server sends true', () {
      final EcoEvent? event = ecoEventFromJson(<String, dynamic>{
        'id': 'evt-mod-ok',
        'title': 'T',
        'description': 'D',
        'category': 'generalCleanup',
        'siteId': 's1',
        'siteName': 'Park',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'scheduledAt': '2026-08-15T09:30:00.000Z',
        'status': 'upcoming',
        'participantCount': 0,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'moderationApproved': true,
      });
      expect(event, isNotNull);
      expect(event!.moderationApproved, isTrue);
    });

    test('ecoEventListFromJson skips entries with unparseable dates', () {
      final List<EcoEvent> events = ecoEventListFromJson(<dynamic>[
        <String, dynamic>{
          'id': 'good',
          'title': 'T',
          'description': 'D',
          'category': 'generalCleanup',
          'siteId': 's1',
          'siteName': 'Park',
          'siteImageUrl': '',
          'organizerId': 'o1',
          'organizerName': 'Org',
          'scheduledAt': '2026-08-15T09:30:00.000Z',
          'status': 'upcoming',
          'participantCount': 0,
          'createdAt': '2026-01-01T00:00:00.000Z',
        },
        <String, dynamic>{
          'id': 'bad',
          'title': 'T2',
          'scheduledAt': 'garbage',
          'status': 'upcoming',
        },
      ]);

      expect(events.length, 1);
      expect(events.first.id, 'good');
    });

    test('attendeeCheckedInAt from API is local after ecoEventFromJson', () {
      final EcoEvent? event = ecoEventFromJson(<String, dynamic>{
        'id': 'evt-tz-full',
        'title': 'T',
        'description': 'D',
        'category': 'generalCleanup',
        'siteId': 's1',
        'siteName': 'Park',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'scheduledAt': '2026-08-15T09:30:00.000Z',
        'endAt': '2026-08-15T11:45:00.000Z',
        'status': 'inProgress',
        'participantCount': 3,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'attendeeCheckInStatus': 'checkedIn',
        'attendeeCheckedInAt': '2026-08-15T13:01:00.000Z',
      });

      expect(event, isNotNull);
      expect(event!.attendeeCheckedInAt, isNotNull);
      expect(event.attendeeCheckedInAt!.isUtc, isFalse,
          reason: 'attendeeCheckedInAt should be converted to local time');
      expect(event.attendeeCheckedInAt!.toUtc().hour, 13);
      expect(event.attendeeCheckedInAt!.toUtc().minute, 1);
    });

    test('maps moderation and check-in flags used by detail + check-in flows', () {
      final EcoEvent? event = ecoEventFromJson(<String, dynamic>{
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

      expect(event, isNotNull);
      expect(event!.moderationApproved, isFalse);
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
