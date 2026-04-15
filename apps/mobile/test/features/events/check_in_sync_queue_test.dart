import 'package:chisto_mobile/features/events/data/check_in_sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('enqueue deduplicates same qrPayload', () async {
    await CheckInSyncQueue.instance.clear();
    final CheckInQueueEntry a = CheckInQueueEntry(
      eventId: 'e1',
      qrPayload: 'payload-a',
      enqueuedAt: DateTime.utc(2026, 1, 1),
    );
    final CheckInQueueEntry b = CheckInQueueEntry(
      eventId: 'e1',
      qrPayload: 'payload-a',
      enqueuedAt: DateTime.utc(2026, 1, 2),
    );
    await CheckInSyncQueue.instance.enqueue(a);
    await CheckInSyncQueue.instance.enqueue(b);
    final List<CheckInQueueEntry> peeked = await CheckInSyncQueue.instance.peek();
    expect(peeked, hasLength(1));
    expect(peeked.single.qrPayload, 'payload-a');
  });

  test('peek returns FIFO order and remove clears one entry', () async {
    await CheckInSyncQueue.instance.clear();
    await CheckInSyncQueue.instance.enqueue(
      CheckInQueueEntry(
        eventId: 'e1',
        qrPayload: 'p1',
        enqueuedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await CheckInSyncQueue.instance.enqueue(
      CheckInQueueEntry(
        eventId: 'e2',
        qrPayload: 'p2',
        enqueuedAt: DateTime.utc(2026, 1, 2),
      ),
    );
    List<CheckInQueueEntry> list = await CheckInSyncQueue.instance.peek();
    expect(list.map((CheckInQueueEntry e) => e.qrPayload).toList(), <String>['p1', 'p2']);

    await CheckInSyncQueue.instance.remove('p1');
    list = await CheckInSyncQueue.instance.peek();
    expect(list.single.qrPayload, 'p2');
  });
}
