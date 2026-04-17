import 'dart:io';

import 'package:chisto_mobile/features/events/data/chat/outbox/chat_outbox_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_platform_interface/src/method_channel_path_provider.dart';
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
    PathProviderPlatform.instance = MethodChannelPathProvider();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
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
