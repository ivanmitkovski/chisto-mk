import 'package:chisto_mobile/features/events/data/event_json.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/shared/current_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCheckInTime', () {
    test('formats UTC DateTime as local HH:mm', () {
      final DateTime utc = DateTime.utc(2026, 6, 15, 13, 1);
      final String formatted = formatCheckInTime(utc);
      final DateTime local = utc.toLocal();
      final String expected =
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      expect(formatted, expected);
    });

    test('formats already-local DateTime correctly', () {
      final DateTime local = DateTime(2026, 6, 15, 15, 5);
      final String formatted = formatCheckInTime(local);
      expect(formatted, '15:05');
    });
  });

  group('EventTime', () {
    test('equality works', () {
      const EventTime a = EventTime(hour: 10, minute: 30);
      const EventTime b = EventTime(hour: 10, minute: 30);
      const EventTime c = EventTime(hour: 11, minute: 0);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('totalMinutes computes correctly', () {
      expect(const EventTime(hour: 10, minute: 30).totalMinutes, 630);
      expect(const EventTime(hour: 0, minute: 0).totalMinutes, 0);
      expect(const EventTime(hour: 23, minute: 59).totalMinutes, 1439);
    });

    test('formatted pads correctly', () {
      expect(const EventTime(hour: 9, minute: 5).formatted, '09:05');
      expect(const EventTime(hour: 14, minute: 0).formatted, '14:00');
    });
  });

  group('EcoEvent', () {
    EcoEvent buildEvent({
      String id = 'evt-1',
      EcoEventStatus status = EcoEventStatus.upcoming,
      String organizerId = 'org-1',
    }) {
      return EcoEvent(
        id: id,
        title: 'Test event',
        description: 'Test',
        category: EcoEventCategory.generalCleanup,
        siteId: '1',
        siteName: 'Test site',
        siteImageUrl: 'assets/test.png',
        siteDistanceKm: 5.0,
        organizerId: organizerId,
        organizerName: 'Organizer',
        date: DateTime(2025, 6, 15),
        startTime: const EventTime(hour: 10, minute: 0),
        endTime: const EventTime(hour: 12, minute: 0),
        participantCount: 5,
        status: status,
        createdAt: DateTime(2025, 6, 10),
      );
    }

    test('equality is based on id and mutable fields', () {
      final EcoEvent a = buildEvent();
      final EcoEvent b = buildEvent();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith produces different event when fields change', () {
      final EcoEvent original = buildEvent();
      final EcoEvent joined = original.copyWith(isJoined: true, participantCount: 6);
      expect(joined.isJoined, isTrue);
      expect(joined.participantCount, 6);
      expect(original, isNot(equals(joined)));
    });

    test('canTransitionTo follows lifecycle state machine', () {
      final EcoEvent upcoming = buildEvent(status: EcoEventStatus.upcoming);
      expect(upcoming.canTransitionTo(EcoEventStatus.inProgress), isTrue);
      expect(upcoming.canTransitionTo(EcoEventStatus.cancelled), isTrue);
      expect(upcoming.canTransitionTo(EcoEventStatus.completed), isFalse);

      final EcoEvent inProgress = buildEvent(status: EcoEventStatus.inProgress);
      expect(inProgress.canTransitionTo(EcoEventStatus.completed), isTrue);
      expect(inProgress.canTransitionTo(EcoEventStatus.cancelled), isTrue);
      expect(inProgress.canTransitionTo(EcoEventStatus.upcoming), isFalse);

      final EcoEvent completed = buildEvent(status: EcoEventStatus.completed);
      expect(completed.canTransitionTo(EcoEventStatus.upcoming), isFalse);
      expect(completed.canTransitionTo(EcoEventStatus.inProgress), isFalse);
    });

    test('isJoinable respects moderation for volunteers', () {
      final EcoEvent pending = buildEvent().copyWith(moderationApproved: false);
      expect(pending.isJoinable, isFalse);
      final EcoEvent approved = buildEvent().copyWith(moderationApproved: true);
      expect(approved.isJoinable, isTrue);
    });

    test('organizer is never joinable via isJoinable', () {
      final EcoEvent orgEvent = buildEvent(
        organizerId: CurrentUser.id,
      ).copyWith(moderationApproved: false);
      expect(orgEvent.isOrganizer, isTrue);
      expect(orgEvent.isJoinable, isFalse);
    });

    test('isBeforeScheduledStart uses scheduledAtUtc when set', () {
      final EcoEvent futureUtc = buildEvent().copyWith(
        scheduledAtUtc: DateTime.utc(2035, 1, 1, 12),
      );
      expect(futureUtc.isBeforeScheduledStart, isTrue);
      final EcoEvent pastUtc = buildEvent().copyWith(
        scheduledAtUtc: DateTime.utc(2020, 1, 1, 12),
      );
      expect(pastUtc.isBeforeScheduledStart, isFalse);
    });

    test('canVolunteerJoinNow is false before scheduledAtUtc when otherwise joinable', () {
      final EcoEvent e = buildEvent().copyWith(
        scheduledAtUtc: DateTime.utc(2035, 1, 1, 12),
      );
      expect(e.isJoinable, isTrue);
      expect(e.canVolunteerJoinNow, isFalse);
    });

    test('canVolunteerJoinNow is true when joinable and start has passed', () {
      final EcoEvent e = buildEvent().copyWith(
        scheduledAtUtc: DateTime.utc(2020, 1, 1, 12),
      );
      expect(e.canVolunteerJoinNow, isTrue);
    });

    test('isValidRange validates time ranges', () {
      expect(
        EcoEvent.isValidRange(
          const EventTime(hour: 10, minute: 0),
          const EventTime(hour: 12, minute: 0),
        ),
        isTrue,
      );
      expect(
        EcoEvent.isValidRange(
          const EventTime(hour: 14, minute: 0),
          const EventTime(hour: 12, minute: 0),
        ),
        isFalse,
      );
      expect(
        EcoEvent.isValidRange(
          const EventTime(hour: 10, minute: 0),
          const EventTime(hour: 10, minute: 0),
        ),
        isFalse,
      );
    });

    test('startDateTime and endDateTime compute correctly', () {
      final EcoEvent event = buildEvent();
      expect(event.startDateTime, DateTime(2025, 6, 15, 10, 0));
      expect(event.endDateTime, DateTime(2025, 6, 15, 12, 0));
    });

    test('fromJson and toJson round-trip', () {
      final EcoEvent original = buildEvent().copyWith(
        gear: <EventGear>[EventGear.gloves, EventGear.trashBags],
        scale: CleanupScale.medium,
        difficulty: EventDifficulty.moderate,
        scheduledAtUtc: DateTime.utc(2025, 6, 15, 8, 30),
        recurrenceSeriesTotal: 3,
        recurrenceSeriesPosition: 2,
        recurrencePrevEventId: 'evt-prev',
        recurrenceNextEventId: 'evt-next',
        organizerAvatarUrl: 'https://signed.example/o.webp',
      );
      final Map<String, dynamic> json = original.toJson();
      final EcoEvent decoded = EcoEvent.fromJson(json);

      expect(decoded.id, original.id);
      expect(decoded.title, original.title);
      expect(decoded.startTime, original.startTime);
      expect(decoded.endTime, original.endTime);
      expect(decoded.gear.length, original.gear.length);
      expect(decoded.scale, original.scale);
      expect(decoded.difficulty, original.difficulty);
      expect(decoded.scheduledAtUtc?.toUtc(), original.scheduledAtUtc?.toUtc());
      expect(decoded.recurrenceSeriesTotal, 3);
      expect(decoded.recurrenceSeriesPosition, 2);
      expect(decoded.recurrencePrevEventId, 'evt-prev');
      expect(decoded.recurrenceNextEventId, 'evt-next');
      expect(decoded.organizerAvatarUrl, 'https://signed.example/o.webp');
    });

    test('ecoEventFromJson sets scheduledAtUtc from scheduledAt', () {
      final EcoEvent? e = ecoEventFromJson(<String, dynamic>{
        'id': 'api-1',
        'title': 'Clean',
        'description': '',
        'category': 'generalCleanup',
        'siteId': 's1',
        'siteName': 'Park',
        'siteImageUrl': '',
        'siteDistanceKm': 1.2,
        'organizerId': 'org',
        'organizerName': 'O',
        'participantCount': 0,
        'status': 'upcoming',
        'createdAt': '2025-06-01T00:00:00.000Z',
        'scheduledAt': '2025-06-15T10:00:00.000Z',
      });
      expect(e, isNotNull);
      expect(e!.scheduledAtUtc, isNotNull);
      expect(
        e.scheduledAtUtc!.toUtc().toIso8601String(),
        '2025-06-15T10:00:00.000Z',
      );
    });

    test('formattedTimeRange', () {
      final EcoEvent event = buildEvent();
      expect(event.formattedTimeRange, '10:00 - 12:00');
    });

    test('copyWith clear flags set nullable fields to null', () {
      final EcoEvent event = buildEvent().copyWith(
        maxParticipants: 50,
        scale: CleanupScale.large,
        difficulty: EventDifficulty.hard,
        organizerAvatarUrl: 'https://example.com/a.png',
      );

      expect(event.maxParticipants, 50);
      expect(event.scale, CleanupScale.large);
      expect(event.difficulty, EventDifficulty.hard);
      expect(event.organizerAvatarUrl, isNotNull);

      final EcoEvent cleared = event.copyWith(
        clearMaxParticipants: true,
        clearScale: true,
        clearDifficulty: true,
        clearOrganizerAvatarUrl: true,
      );

      expect(cleared.maxParticipants, isNull);
      expect(cleared.scale, isNull);
      expect(cleared.difficulty, isNull);
      expect(cleared.organizerAvatarUrl, isNull);
    });

    test('hashCode is consistent with == for equal events', () {
      final EcoEvent a = buildEvent().copyWith(
        gear: <EventGear>[EventGear.gloves],
        afterImagePaths: <String>['a.jpg', 'b.jpg'],
      );
      final EcoEvent b = buildEvent().copyWith(
        gear: <EventGear>[EventGear.gloves],
        afterImagePaths: <String>['a.jpg', 'b.jpg'],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs when == fields differ', () {
      final EcoEvent a = buildEvent();
      final EcoEvent b = buildEvent().copyWith(description: 'Different');

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('fromJson filters non-String gear items instead of throwing', () {
      final EcoEvent event = EcoEvent.fromJson(<String, dynamic>{
        'id': 'evt-gear',
        'title': 'T',
        'description': 'D',
        'category': 'generalCleanup',
        'siteId': 's1',
        'siteName': 'Site',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'date': '2026-06-15T00:00:00.000Z',
        'participantCount': 0,
        'status': 'upcoming',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'gear': <dynamic>['gloves', 42, null, 'rakes'],
      });

      expect(event.gear.length, 2);
      expect(event.gear, contains(EventGear.gloves));
      expect(event.gear, contains(EventGear.rakes));
    });

    test('fromJson falls back gracefully for unknown enum values', () {
      final EcoEvent event = EcoEvent.fromJson(<String, dynamic>{
        'id': 'evt-unk',
        'title': 'T',
        'description': 'D',
        'category': 'futureCategory',
        'siteId': 's1',
        'siteName': 'Site',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'date': '2026-06-15T00:00:00.000Z',
        'participantCount': 0,
        'status': 'futureStatus',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'difficulty': 'extreme',
        'scale': 'gigantic',
        'gear': <String>['jetpack'],
      });

      expect(event.category, EcoEventCategory.generalCleanup);
      expect(event.status, EcoEventStatus.upcoming);
      expect(event.difficulty, EventDifficulty.easy);
      expect(event.scale, CleanupScale.small);
      expect(event.gear, contains(EventGear.trashBags));
    });

    test('fromJson converts UTC attendeeCheckedInAt to local time', () {
      final EcoEvent event = EcoEvent.fromJson(<String, dynamic>{
        'id': 'evt-tz',
        'title': 'TZ',
        'description': 'D',
        'category': 'generalCleanup',
        'siteId': 's1',
        'siteName': 'Site',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'date': '2026-06-15T00:00:00.000Z',
        'participantCount': 0,
        'status': 'inProgress',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'attendeeCheckInStatus': 'checkedIn',
        'attendeeCheckedInAt': '2026-06-15T13:01:00.000Z',
      });

      expect(event.attendeeCheckedInAt, isNotNull);
      expect(event.attendeeCheckedInAt!.isUtc, isFalse);
      final DateTime utcBack = event.attendeeCheckedInAt!.toUtc();
      expect(utcBack.hour, 13);
      expect(utcBack.minute, 1);
    });

    test('fromJson converts UTC reminderAt to local time', () {
      final EcoEvent event = EcoEvent.fromJson(<String, dynamic>{
        'id': 'evt-rem-tz',
        'title': 'TZ',
        'description': 'D',
        'category': 'generalCleanup',
        'siteId': 's1',
        'siteName': 'Site',
        'siteImageUrl': '',
        'organizerId': 'o1',
        'organizerName': 'Org',
        'date': '2026-06-15T00:00:00.000Z',
        'participantCount': 0,
        'status': 'upcoming',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'reminderAt': '2026-06-15T07:30:00.000Z',
      });

      expect(event.reminderAt, isNotNull);
      expect(event.reminderAt!.isUtc, isFalse);
      final DateTime utcBack = event.reminderAt!.toUtc();
      expect(utcBack.hour, 7);
      expect(utcBack.minute, 30);
    });
  });

  group('CheckInQrPayload', () {
    test('equality works', () {
      const CheckInQrPayload a = CheckInQrPayload(
        eventId: 'e1', sessionId: 's1', nonce: 'n1', issuedAtMs: 100,
      );
      const CheckInQrPayload b = CheckInQrPayload(
        eventId: 'e1', sessionId: 's1', nonce: 'n1', issuedAtMs: 100,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('isExpired checks TTL correctly', () {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final CheckInQrPayload fresh = CheckInQrPayload(
        eventId: 'e1', sessionId: 's1', nonce: 'n1', issuedAtMs: now,
      );
      final CheckInQrPayload old = CheckInQrPayload(
        eventId: 'e1', sessionId: 's1', nonce: 'n1', issuedAtMs: now - 60000,
      );

      expect(fresh.isExpired(const Duration(seconds: 45)), isFalse);
      expect(old.isExpired(const Duration(seconds: 45)), isTrue);
    });
  });

  group('CheckedInAttendee', () {
    test('toJson and fromJson round-trip', () {
      final CheckedInAttendee original = CheckedInAttendee(
        id: 'user-1',
        name: 'Alice',
        checkedInAt: DateTime(2025, 6, 15, 10, 30),
      );
      final Map<String, dynamic> json = original.toJson();
      final CheckedInAttendee? decoded = CheckedInAttendee.fromJson(json);

      expect(decoded, isNotNull);
      expect(decoded!.id, 'user-1');
      expect(decoded.name, 'Alice');
      expect(decoded.userId, isNull);
      expect(decoded.checkedInAt.millisecondsSinceEpoch,
          original.checkedInAt.millisecondsSinceEpoch);
    });

    test('toJson and fromJson preserves userId when set', () {
      final CheckedInAttendee original = CheckedInAttendee(
        id: 'row-1',
        name: 'Bob',
        checkedInAt: DateTime(2025, 6, 15, 11, 0),
        userId: 'usr_abc',
      );
      final CheckedInAttendee? decoded =
          CheckedInAttendee.fromJson(original.toJson());
      expect(decoded?.userId, 'usr_abc');
    });

    test('toJson and fromJson preserves avatarUrl when set', () {
      final CheckedInAttendee original = CheckedInAttendee(
        id: 'row-1',
        name: 'Bob',
        checkedInAt: DateTime(2025, 6, 15, 11, 0),
        userId: 'usr_abc',
        avatarUrl: 'https://example.com/a.jpg',
      );
      final CheckedInAttendee? decoded =
          CheckedInAttendee.fromJson(original.toJson());
      expect(decoded?.avatarUrl, 'https://example.com/a.jpg');
    });

    test('equality is based on id', () {
      final CheckedInAttendee a = CheckedInAttendee(
        id: 'u1', name: 'A', checkedInAt: DateTime(2025, 1, 1),
      );
      final CheckedInAttendee b = CheckedInAttendee(
        id: 'u1', name: 'B', checkedInAt: DateTime(2025, 6, 1),
      );
      expect(a, equals(b));
    });
  });
}
