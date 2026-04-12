import 'package:chisto_mobile/features/events/data/participants_json.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('eventParticipantsPageFromJson parses data and meta', () {
    final EventParticipantsPage page = eventParticipantsPageFromJson(<String, dynamic>{
      'data': <dynamic>[
        <String, dynamic>{
          'userId': 'u1',
          'displayName': 'Ana Miteva',
          'joinedAt': '2025-06-01T10:00:00.000Z',
        },
      ],
      'meta': <String, dynamic>{
        'hasMore': true,
        'nextCursor': 'abc',
      },
    });

    expect(page.items, hasLength(1));
    expect(page.items.single.userId, 'u1');
    expect(page.items.single.displayName, 'Ana Miteva');
    expect(page.items.single.joinedAt.toUtc().toIso8601String(), '2025-06-01T10:00:00.000Z');
    expect(page.hasMore, isTrue);
    expect(page.nextCursor, 'abc');
  });

  test('eventParticipantsPageFromJson tolerates empty payload', () {
    final EventParticipantsPage page = eventParticipantsPageFromJson(<String, dynamic>{});
    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
    expect(page.nextCursor, isNull);
  });
}
