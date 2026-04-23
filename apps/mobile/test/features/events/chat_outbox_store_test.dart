import 'dart:io';

import 'package:chisto_mobile/features/events/data/chat/outbox/chat_outbox_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_outbox_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    await ChatOutboxStore.shared.clearAll();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('isOutboxFullForEvent is true at cap', () async {
    final ChatOutboxStore store = ChatOutboxStore.shared;
    await store.clearAll();
    const String eventId = 'e-cap';
    for (int i = 0; i < ChatOutboxStore.maxPendingTextRowsPerEvent; i++) {
      final String hex = i.toRadixString(16).padLeft(12, '0');
      final bool ok = await store.enqueueText(
        eventId: eventId,
        tempId: 't$i',
        clientMessageId: '00000000-0000-4000-8000-$hex',
        body: 'm',
      );
      expect(ok, isTrue);
    }
    expect(await store.isOutboxFullForEvent(eventId), isTrue);
    final bool overflow = await store.enqueueText(
      eventId: eventId,
      tempId: 'overflow',
      clientMessageId: '10000000-0000-4000-8000-000000000099',
      body: 'x',
    );
    expect(overflow, isFalse);
  });

  test('peekNextGlobally returns oldest pending row across events', () async {
    final ChatOutboxStore store = ChatOutboxStore.shared;
    await store.clearAll();
    await store.enqueueText(
      eventId: 'e-later',
      tempId: 't2',
      clientMessageId: '00000000-0000-4000-8000-000000000002',
      body: 'second',
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await store.enqueueText(
      eventId: 'e-earlier',
      tempId: 't1',
      clientMessageId: '00000000-0000-4000-8000-000000000001',
      body: 'first',
    );
    final ChatOutboxEntry? next = await store.peekNextGlobally();
    expect(next, isNotNull);
    expect(next!.eventId, 'e-later');
    expect(await store.totalPendingCount(), 2);
    expect(await store.totalFailedCount(), 0);
  });

  test('clearAll removes rows after enqueue', () async {
    final ChatOutboxStore store = ChatOutboxStore.shared;
    await store.clearAll();
    final bool ok = await store.enqueueText(
      eventId: 'e-clear',
      tempId: 't1',
      clientMessageId: '00000000-0000-4000-8000-000000000001',
      body: 'hello',
    );
    expect(ok, isTrue);
    expect((await store.listPending('e-clear')).length, 1);

    await store.clearAll();

    expect(await store.listPending('e-clear'), isEmpty);
  });
}
