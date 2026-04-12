import 'package:chisto_mobile/features/events/data/chat/chat_client_message_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('newChatClientMessageId returns RFC4122 v4 shape', () {
    final String id = newChatClientMessageId();
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(id),
      isTrue,
    );
  });

  test('newChatClientMessageId returns unique values', () {
    final Set<String> set = <String>{};
    for (int i = 0; i < 50; i++) {
      set.add(newChatClientMessageId());
    }
    expect(set.length, 50);
  });
}
