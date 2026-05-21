import 'package:chisto_mobile/features/notifications/data/pending_chat_reply_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PendingChatReplyStore.clear();
  });

  test('enqueue and drain round-trip', () async {
    await PendingChatReplyStore.enqueue(
      const PendingChatReply(eventId: 'evt1', body: 'hello'),
    );
    final List<PendingChatReply> drained = await PendingChatReplyStore.drainAll();
    expect(drained, hasLength(1));
    expect(drained.first.eventId, 'evt1');
    expect(drained.first.body, 'hello');
    expect(await PendingChatReplyStore.peekAll(), isEmpty);
  });
}
