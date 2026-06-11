import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/event_update_payload.dart';
import 'package:feature_events/src/presentation/utils/edit_event_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EcoEvent _event({
  String title = 'River cleanup',
  int? maxParticipants = 10,
  List<EventGear> gear = const <EventGear>[EventGear.gloves],
}) {
  return EcoEvent(
    id: 'e1',
    title: title,
    description: 'D',
    category: EcoEventCategory.generalCleanup,
    siteId: 's1',
    siteName: 'Site',
    siteImageUrl: '',
    siteDistanceKm: 1,
    organizerId: 'org',
    organizerName: 'Org',
    date: DateTime.utc(2026, 6, 15),
    startTime: const EventTime(hour: 10, minute: 0),
    endTime: const EventTime(hour: 12, minute: 0),
    participantCount: 0,
    status: EcoEventStatus.upcoming,
    createdAt: DateTime.utc(2026, 1, 1),
    maxParticipants: maxParticipants,
    gear: gear,
    scale: CleanupScale.small,
    difficulty: EventDifficulty.easy,
  );
}

void main() {
  group('EditEventFormSnapshot', () {
    test('matches ignores gear order', () {
      final EditEventFormSnapshot s = EditEventFormSnapshot.fromEvent(
        _event(gear: <EventGear>[EventGear.gloves, EventGear.trashBags]),
      );
      expect(
        s.matches(
          titleTrimmed: 'River cleanup',
          descriptionTrimmed: 'D',
          maxParticipants: 10,
          dateOnly: DateUtils.dateOnly(DateTime.utc(2026, 6, 15)),
          endDateOnly: DateUtils.dateOnly(DateTime.utc(2026, 6, 15)),
          startTime: const EventTime(hour: 10, minute: 0),
          endTime: const EventTime(hour: 12, minute: 0),
          category: EcoEventCategory.generalCleanup,
          gear: <EventGear>{EventGear.trashBags, EventGear.gloves},
          scale: CleanupScale.small,
          difficulty: EventDifficulty.easy,
        ),
        isTrue,
      );
    });

    test(
      'buildPartialPayload includes scheduledAt when date changes',
      () {
        final EditEventFormSnapshot s = EditEventFormSnapshot.fromEvent(
          _event(),
        );
        final DateTime newStart = DateTime.utc(2026, 6, 20, 10, 0);
        final DateTime newEnd = DateTime.utc(2026, 6, 20, 12, 0);
        final EventUpdatePayload p = s.buildPartialPayload(
          titleTrimmed: 'River cleanup',
          descriptionTrimmed: 'D',
          maxParticipants: 10,
          scheduledAtUtc: newStart,
          endAtUtc: newEnd,
          category: EcoEventCategory.generalCleanup,
          gear: <EventGear>[EventGear.gloves],
          scale: CleanupScale.small,
          difficulty: EventDifficulty.easy,
        );
        final Map<String, dynamic> json = p.toPatchJson();
        expect(json.containsKey('scheduledAt'), isTrue);
        expect(json.containsKey('endAt'), isTrue);
      },
    );

    test('buildPartialPayload includes description when only text changes', () {
      final EditEventFormSnapshot s = EditEventFormSnapshot.fromEvent(
        _event(),
      );
      final EventUpdatePayload p = s.buildPartialPayload(
        titleTrimmed: 'River cleanup',
        descriptionTrimmed: 'Updated description',
        maxParticipants: 10,
        scheduledAtUtc: DateTime.utc(2026, 6, 15, 10, 0),
        endAtUtc: DateTime.utc(2026, 6, 15, 12, 0),
        category: EcoEventCategory.generalCleanup,
        gear: <EventGear>[EventGear.gloves],
        scale: CleanupScale.small,
        difficulty: EventDifficulty.easy,
      );
      expect(p.toPatchJson()['description'], 'Updated description');
    });

    test(
      'buildPartialPayload sends maxParticipants null when clearing cap',
      () {
        final EditEventFormSnapshot s = EditEventFormSnapshot.fromEvent(
          _event(maxParticipants: 10),
        );
        final EventUpdatePayload p = s.buildPartialPayload(
          titleTrimmed: 'River cleanup',
          descriptionTrimmed: 'D',
          maxParticipants: null,
          scheduledAtUtc: DateTime.utc(2026, 6, 15, 10, 0),
          endAtUtc: DateTime.utc(2026, 6, 15, 12, 0),
          category: EcoEventCategory.generalCleanup,
          gear: <EventGear>[EventGear.gloves],
          scale: CleanupScale.small,
          difficulty: EventDifficulty.easy,
        );
        final Map<String, dynamic> json = p.toPatchJson();
        expect(json.containsKey('maxParticipants'), isTrue);
        expect(json['maxParticipants'], isNull);
      },
    );
  });

  group('editEventTitleIssueKey', () {
    test('too short', () {
      expect(editEventTitleIssueKey('ab'), 'tooShort');
    });
    test('too long', () {
      expect(editEventTitleIssueKey('a' * 201), 'tooLong');
    });
    test('ok at boundary', () {
      expect(editEventTitleIssueKey('a' * 3), isNull);
      expect(editEventTitleIssueKey('a' * 200), isNull);
    });
  });

  group('editEventMaxParticipantsIssueKey', () {
    test('empty ok', () {
      expect(editEventMaxParticipantsIssueKey(''), isNull);
    });
    test('range', () {
      expect(editEventMaxParticipantsIssueKey('1'), 'range');
      expect(editEventMaxParticipantsIssueKey('5001'), 'range');
    });
  });
}
