import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_read_cursor.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_stream_event.dart';
import 'package:chisto_mobile/features/events/data/chat/in_memory_event_chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sendMessage and stream emits created', () async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    final List<EventChatStreamEvent> seen = <EventChatStreamEvent>[];
    final sub = repo.messageStream('e1').listen(seen.add);
    await repo.sendMessage('e1', 'hi');
    await Future<void>.delayed(Duration.zero);
    expect(seen, isNotEmpty);
    expect(seen.first, isA<EventChatStreamMessageCreated>());
    await sub.cancel();
    repo.dispose();
  });

  test('fetchMessages pagination cursor', () async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage(
      'e1',
      authorId: 'a',
      authorName: 'A',
      body: 'one',
    );
    await repo.seedOtherMessage(
      'e1',
      authorId: 'b',
      authorName: 'B',
      body: 'two',
    );
    final first = await repo.fetchMessages('e1', limit: 1);
    expect(first.messages.length, 1);
    final second = await repo.fetchMessages('e1', cursor: first.nextCursor, limit: 10);
    expect(second.messages.length, 1);
    repo.dispose();
  });

  test('editMessage sets editedAt and emits edited', () async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    final List<EventChatStreamEvent> seen = <EventChatStreamEvent>[];
    final sub = repo.messageStream('e1').listen(seen.add);
    await repo.sendMessage('e1', 'a');
    final String id = (await repo.fetchMessages('e1', limit: 1)).messages.first.id;
    await repo.editMessage('e1', id, 'b');
    await Future<void>.delayed(Duration.zero);
    expect(seen.whereType<EventChatStreamMessageEdited>(), isNotEmpty);
    final page = await repo.fetchMessages('e1', limit: 1);
    expect(page.messages.first.body, 'b');
    expect(page.messages.first.editedAt, isNotNull);
    await sub.cancel();
    repo.dispose();
  });

  test('searchMessages filters body', () async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage('e1', authorId: 'x', authorName: 'X', body: 'alpha beta');
    await repo.seedOtherMessage('e1', authorId: 'y', authorName: 'Y', body: 'gamma');
    final r = await repo.searchMessages('e1', 'beta', limit: 10);
    expect(r.messages.length, 1);
    expect(r.messages.first.body, contains('beta'));
    repo.dispose();
  });

  test('setPin and fetchPinnedMessages', () async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage('e1', authorId: 'x', authorName: 'X', body: 'pin me');
    final String id = (await repo.fetchMessages('e1', limit: 1)).messages.first.id;
    await repo.setPin('e1', id, pinned: true);
    final pinned = await repo.fetchPinnedMessages('e1');
    expect(pinned.length, 1);
    expect(pinned.first.isPinned, true);
    repo.dispose();
  });

  test('mute status roundtrip', () async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    expect(await repo.fetchMuteStatus('e1'), false);
    await repo.setMuteStatus('e1', true);
    expect(await repo.fetchMuteStatus('e1'), true);
    await repo.setMuteStatus('e1', false);
    expect(await repo.fetchMuteStatus('e1'), false);
    repo.dispose();
  });

  test('fetchReadCursors merges participants with stored cursors', () async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage('e1', authorId: 'peer', authorName: 'Peer', body: 'hi');
    final EventChatMessage mine = await repo.sendMessage('e1', 'own');
    repo.setReadCursorForUser(
      'e1',
      userId: 'peer',
      displayName: 'Peer',
      lastReadMessageId: mine.id,
      lastReadMessageCreatedAt: mine.createdAt,
    );
    final List<EventChatReadCursor> cursors = await repo.fetchReadCursors('e1');
    EventChatReadCursor? peer;
    for (final EventChatReadCursor c in cursors) {
      if (c.userId == 'peer') {
        peer = c;
        break;
      }
    }
    expect(peer, isNotNull);
    expect(peer!.lastReadMessageId, mine.id);
    repo.dispose();
  });

  test('markRead emits read_cursor SSE for event scope', () async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    final List<EventChatStreamEvent> seen = <EventChatStreamEvent>[];
    final sub = repo.messageStream('e1').listen(seen.add);
    await repo.sendMessage('e1', 'x');
    final String id = (await repo.fetchMessages('e1', limit: 1)).messages.first.id;
    await repo.markRead('e1', id);
    await Future<void>.delayed(Duration.zero);
    expect(seen.whereType<EventChatStreamReadCursorUpdated>(), isNotEmpty);
    await sub.cancel();
    repo.dispose();
  });
}
