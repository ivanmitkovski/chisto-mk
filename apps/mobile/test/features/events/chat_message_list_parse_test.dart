import 'package:chisto_mobile/features/events/data/chat/chat_message_list_parse.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseEventChatMessageBatch maps viewer and filters invalid rows', () {
    final List<Map<String, dynamic>> raw = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'm1',
        'eventId': 'e1',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'body': 'Hi',
        'isDeleted': false,
        'author': <String, dynamic>{
          'id': 'a1',
          'displayName': 'Pat',
          'avatarUrl': 'https://signed.example/p.webp',
        },
      },
      <String, dynamic>{'invalid': true},
    ];
    final List<EventChatMessage> out = parseEventChatMessageBatch(
      ChatMessageListParseArg(rawMaps: raw, viewerUserId: 'me'),
    );
    expect(out, hasLength(1));
    expect(out.first.id, 'm1');
    expect(out.first.isOwnMessage, isFalse);
    expect(out.first.authorAvatarUrl, 'https://signed.example/p.webp');
  });
}
