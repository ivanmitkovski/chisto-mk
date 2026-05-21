import 'package:chisto_mobile/features/notifications/data/event_chat_mark_read_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromResponseJson parses inbox sync meta', () {
    final EventChatMarkReadResult? r = EventChatMarkReadResult.fromResponseJson(
      <String, dynamic>{
        'data': <String, dynamic>{'ok': true},
        'meta': <String, dynamic>{
          'timestamp': '2026-01-01T00:00:00.000Z',
          'unreadCount': 4,
          'eventChatNotificationsMarkedRead': 2,
        },
      },
    );
    expect(r?.unreadCount, 4);
    expect(r?.eventChatNotificationsMarkedRead, 2);
  });

  test('fromResponseJson returns null without meta', () {
    expect(
      EventChatMarkReadResult.fromResponseJson(<String, dynamic>{'data': <String, dynamic>{}}),
      isNull,
    );
  });
}
