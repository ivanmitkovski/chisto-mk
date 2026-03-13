import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        organizerId: 'org-1',
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
    });

    test('formattedDate and formattedTimeRange', () {
      final EcoEvent event = buildEvent();
      expect(event.formattedDate, 'June 15, 2025');
      expect(event.formattedTimeRange, '10:00 - 12:00');
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
      expect(decoded.checkedInAt.millisecondsSinceEpoch,
          original.checkedInAt.millisecondsSinceEpoch);
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
