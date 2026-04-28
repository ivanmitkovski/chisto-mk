import 'package:chisto_mobile/features/home/data/engagement_outbox_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recordRetryableFlushFailure increments failCount then drops at max', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const EngagementOutboxEntry entry = EngagementOutboxEntry(
      id: 'e1',
      kind: EngagementOutboxKind.upvote,
      siteId: 's1',
      enqueuedAtMs: 1,
    );
    await EngagementOutboxStore.instance.enqueue(entry);
    for (var i = 0; i < 4; i++) {
      await EngagementOutboxStore.instance.recordRetryableFlushFailure('e1');
    }
    var list = await EngagementOutboxStore.instance.peek();
    expect(list.single.failCount, 4);
    await EngagementOutboxStore.instance.recordRetryableFlushFailure('e1');
    list = await EngagementOutboxStore.instance.peek();
    expect(list, isEmpty);
  });
}
