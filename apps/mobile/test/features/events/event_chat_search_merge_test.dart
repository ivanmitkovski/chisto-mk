import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_chat_search_merge.dart';
import 'package:flutter_test/flutter_test.dart';

EventChatMessage _msg({
  required String id,
  required String body,
  required DateTime createdAt,
  bool deleted = false,
}) {
  return EventChatMessage(
    id: id,
    eventId: 'e1',
    authorId: 'u1',
    authorName: 'A',
    createdAt: createdAt,
    body: body,
    isDeleted: deleted,
    isOwnMessage: false,
  );
}

void main() {
  test('mergeEventChatSearchHits prefers live copy from allMessages', () {
    final EventChatMessage server = _msg(
      id: 'm1',
      body: 'old',
      createdAt: DateTime.utc(2024, 1, 2),
    );
    final EventChatMessage live = _msg(
      id: 'm1',
      body: 'hello river',
      createdAt: DateTime.utc(2024, 1, 2),
    );
    final List<EventChatMessage> merged = mergeEventChatSearchHits(
      serverHits: <EventChatMessage>[server],
      allMessages: <EventChatMessage>[live],
      query: 'river',
    );
    expect(merged, hasLength(1));
    expect(merged.single.body, 'hello river');
  });

  test('mergeEventChatSearchHits adds local-only matches and sorts newest first', () {
    final EventChatMessage older = _msg(
      id: 'old',
      body: 'alpha beta',
      createdAt: DateTime.utc(2024, 1, 1),
    );
    final EventChatMessage newer = _msg(
      id: 'new',
      body: 'gamma beta',
      createdAt: DateTime.utc(2024, 1, 3),
    );
    final List<EventChatMessage> all = <EventChatMessage>[older, newer];
    final List<EventChatMessage> merged = mergeEventChatSearchHits(
      serverHits: <EventChatMessage>[],
      allMessages: all,
      query: 'beta',
    );
    expect(merged.map((EventChatMessage m) => m.id).toList(), <String>['new', 'old']);
  });

  test('localEventChatSearchMatches excludes deleted', () {
    final List<EventChatMessage> all = <EventChatMessage>[
      _msg(id: 'a', body: 'findme', createdAt: DateTime.utc(2024, 1, 1)),
      _msg(id: 'b', body: 'findme too', createdAt: DateTime.utc(2024, 1, 2), deleted: true),
    ];
    expect(localEventChatSearchMatches(all, 'findme'), hasLength(1));
  });

  test('eventChatSearchMergedIncludesLocalOnly', () {
    final List<EventChatMessage> merged = mergeEventChatSearchHits(
      serverHits: <EventChatMessage>[_msg(id: 's', body: 'x', createdAt: DateTime.utc(2024, 1, 1))],
      allMessages: <EventChatMessage>[
        _msg(id: 's', body: 'x', createdAt: DateTime.utc(2024, 1, 1)),
        _msg(id: 'local', body: 'local only', createdAt: DateTime.utc(2024, 1, 2)),
      ],
      query: 'only',
    );
    expect(
      eventChatSearchMergedIncludesLocalOnly(
        serverHits: <EventChatMessage>[
          _msg(id: 's', body: 'x', createdAt: DateTime.utc(2024, 1, 1)),
        ],
        merged: merged,
      ),
      isTrue,
    );
    expect(
      eventChatSearchMergedIncludesLocalOnly(
        serverHits: merged,
        merged: merged,
      ),
      isFalse,
    );
  });
}
