import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_chat_message_list_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('insertEventChatMessageSorted keeps ascending order', () {
    final List<EventChatMessage> list = <EventChatMessage>[
      EventChatMessage(
        id: 'a',
        eventId: 'e',
        authorId: 'u1',
        authorName: 'A',
        createdAt: DateTime.utc(2026, 1, 2),
        body: 'x',
        isDeleted: false,
        isOwnMessage: false,
        pending: false,
        messageType: EventChatMessageType.text,
      ),
      EventChatMessage(
        id: 'b',
        eventId: 'e',
        authorId: 'u1',
        authorName: 'A',
        createdAt: DateTime.utc(2026, 1, 4),
        body: 'y',
        isDeleted: false,
        isOwnMessage: false,
        pending: false,
        messageType: EventChatMessageType.text,
      ),
    ];

    insertEventChatMessageSorted(
      list,
      EventChatMessage(
        id: 'c',
        eventId: 'e',
        authorId: 'u1',
        authorName: 'A',
        createdAt: DateTime.utc(2026, 1, 3),
        body: 'mid',
        isDeleted: false,
        isOwnMessage: false,
        pending: false,
        messageType: EventChatMessageType.text,
      ),
    );

    expect(list.map((EventChatMessage m) => m.id).join(','), 'a,c,b');
  });
}
