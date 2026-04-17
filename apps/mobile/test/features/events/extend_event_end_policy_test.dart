import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/extend_event_end_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EcoEvent build({
    required DateTime date,
    required EventTime start,
    required EventTime end,
  }) {
    return EcoEvent(
      id: 'e1',
      title: 'T',
      description: 'D',
      category: EcoEventCategory.generalCleanup,
      siteId: 's',
      siteName: 'Site',
      siteImageUrl: '',
      siteDistanceKm: 1,
      organizerId: 'current_user',
      organizerName: 'You',
      date: date,
      startTime: start,
      endTime: end,
      participantCount: 1,
      status: EcoEventStatus.inProgress,
      createdAt: DateTime(2026, 1, 1),
      isJoined: true,
      moderationApproved: true,
    );
  }

  test('clamp keeps +15 within same day when under policy cap', () {
    final EcoEvent e = build(
      date: DateTime(2026, 6, 1),
      start: const EventTime(hour: 10, minute: 0),
      end: const EventTime(hour: 11, minute: 0),
    );
    final DateTime bumped = clampProposedEndLocal(
      event: e,
      candidate: DateTime(2026, 6, 1, 11, 15),
    );
    expect(bumped, DateTime(2026, 6, 1, 11, 15));
  });

  test('clamp pulls next-day candidate back to end of event calendar day', () {
    final EcoEvent e = build(
      date: DateTime(2026, 6, 1),
      start: const EventTime(hour: 10, minute: 0),
      end: const EventTime(hour: 22, minute: 0),
    );
    final DateTime bumped = clampProposedEndLocal(
      event: e,
      candidate: DateTime(2026, 6, 2, 1, 0),
    );
    expect(bumped, DateTime(2026, 6, 1, 23, 59));
  });
}
