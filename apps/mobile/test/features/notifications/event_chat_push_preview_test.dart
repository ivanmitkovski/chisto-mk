import 'package:feature_notifications/src/data/event_chat_push_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localizedForMessageType returns voice label for AUDIO', () {
    expect(
      EventChatPushPreview.localizedForMessageType('AUDIO', null),
      'Voice message',
    );
  });

  test('resolveMessageBody uses messagePreview first', () {
    expect(
      EventChatPushPreview.resolveMessageBody(<String, dynamic>{
        'messagePreview': 'Hi',
        'messageType': 'TEXT',
      }),
      'Hi',
    );
  });

  test('resolveNotificationBody strips empty sender suffix', () {
    expect(
      EventChatPushPreview.resolveNotificationBody(<String, dynamic>{
        'type': 'EVENT_CHAT',
        'messageType': 'AUDIO',
        'senderName': 'Alex',
        'body': 'Alex: ',
      }),
      'Alex: Voice message',
    );
  });
}
