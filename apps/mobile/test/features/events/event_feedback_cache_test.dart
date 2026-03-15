import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventFeedbackSnapshot', () {
    final DateTime createdAt = DateTime(2025, 6, 15, 14, 30);

    EventFeedbackSnapshot buildSnapshot({
      String eventId = 'evt-1',
      int rating = 5,
      int bagsCollected = 3,
      double volunteerHours = 2.5,
      String notes = 'Great event',
      DateTime? createdAt,
    }) {
      return EventFeedbackSnapshot(
        eventId: eventId,
        rating: rating,
        bagsCollected: bagsCollected,
        volunteerHours: volunteerHours,
        notes: notes,
        createdAt: createdAt ?? DateTime(2025, 6, 15, 14, 30),
      );
    }

    test('toJson and fromJson round-trip', () {
      final EventFeedbackSnapshot original = buildSnapshot();

      final Map<String, dynamic> json = original.toJson();
      final EventFeedbackSnapshot decoded = EventFeedbackSnapshot.fromJson(json);

      expect(decoded.eventId, original.eventId);
      expect(decoded.rating, original.rating);
      expect(decoded.bagsCollected, original.bagsCollected);
      expect(decoded.volunteerHours, original.volunteerHours);
      expect(decoded.notes, original.notes);
      expect(decoded.createdAt.millisecondsSinceEpoch,
          original.createdAt.millisecondsSinceEpoch);
    });

    test('fromJson uses default values for missing fields', () {
      final Map<String, dynamic> minimal = <String, dynamic>{
        'eventId': 'evt-42',
      };

      final EventFeedbackSnapshot decoded = EventFeedbackSnapshot.fromJson(minimal);

      expect(decoded.eventId, 'evt-42');
      expect(decoded.rating, 5);
      expect(decoded.bagsCollected, 0);
      expect(decoded.volunteerHours, 1.0);
      expect(decoded.notes, '');
      expect(decoded.createdAt, isNotNull);
    });

    test('fromJson clamps rating to 1-5', () {
      final EventFeedbackSnapshot low = EventFeedbackSnapshot.fromJson(
        <String, dynamic>{'eventId': 'e1', 'rating': 0},
      );
      final EventFeedbackSnapshot high = EventFeedbackSnapshot.fromJson(
        <String, dynamic>{'eventId': 'e1', 'rating': 10},
      );

      expect(low.rating, 1);
      expect(high.rating, 5);
    });

    test('fromJson clamps bagsCollected to 0-100000', () {
      final EventFeedbackSnapshot negative = EventFeedbackSnapshot.fromJson(
        <String, dynamic>{'eventId': 'e1', 'bagsCollected': -5},
      );
      final EventFeedbackSnapshot over = EventFeedbackSnapshot.fromJson(
        <String, dynamic>{'eventId': 'e1', 'bagsCollected': 200000},
      );

      expect(negative.bagsCollected, 0);
      expect(over.bagsCollected, 100000);
    });

    test('fromJson clamps volunteerHours to 0.5-24.0', () {
      final EventFeedbackSnapshot low = EventFeedbackSnapshot.fromJson(
        <String, dynamic>{'eventId': 'e1', 'volunteerHours': 0.1},
      );
      final EventFeedbackSnapshot high = EventFeedbackSnapshot.fromJson(
        <String, dynamic>{'eventId': 'e1', 'volunteerHours': 30.0},
      );

      expect(low.volunteerHours, 0.5);
      expect(high.volunteerHours, 24.0);
    });

    test('estimatedKg computes correctly', () {
      final EventFeedbackSnapshot snapshot = buildSnapshot(bagsCollected: 5);

      expect(snapshot.estimatedKg, 16.0); // 5 * 3.2
    });

    test('estimatedCo2SavedKg computes correctly', () {
      final EventFeedbackSnapshot snapshot = buildSnapshot(bagsCollected: 5);

      expect(snapshot.estimatedCo2SavedKg, 11.2); // 16.0 * 0.7
    });

    test('copyWith produces new instance with updated fields', () {
      final EventFeedbackSnapshot original = buildSnapshot();
      final EventFeedbackSnapshot updated = original.copyWith(
        rating: 4,
        bagsCollected: 10,
        notes: 'Updated notes',
      );

      expect(updated.eventId, original.eventId);
      expect(updated.rating, 4);
      expect(updated.bagsCollected, 10);
      expect(updated.notes, 'Updated notes');
      expect(updated.volunteerHours, original.volunteerHours);
    });
  });
}
