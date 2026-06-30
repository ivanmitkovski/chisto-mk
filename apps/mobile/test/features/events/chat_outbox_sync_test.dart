import 'dart:io';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_events/src/data/chat/chat_outbox_sync.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/data/chat/event_chat_repository.dart';
import 'package:feature_events/src/data/chat/outbox/chat_outbox_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

class _FakeEventChatRepository implements EventChatRepository {
  _FakeEventChatRepository({this.onSend});

  Future<EventChatMessage> Function(
    String eventId,
    String body, {
    String? replyToId,
    String? clientMessageId,
  })?
  onSend;

  @override
  Future<EventChatMessage> sendMessage(
    String eventId,
    String body, {
    String? replyToId,
    List<EventChatAttachment>? attachments,
    double? locationLat,
    double? locationLng,
    String? locationLabel,
    String? clientMessageId,
  }) async {
    final Future<EventChatMessage> Function(
      String eventId,
      String body, {
      String? replyToId,
      String? clientMessageId,
    })?
    handler = onSend;
    if (handler != null) {
      return handler(
        eventId,
        body,
        replyToId: replyToId,
        clientMessageId: clientMessageId,
      );
    }
    return EventChatMessage(
      id: 'msg-1',
      eventId: eventId,
      authorId: 'me',
      authorName: 'You',
      createdAt: DateTime.utc(2026, 5, 1),
      body: body,
      isDeleted: false,
      isOwnMessage: true,
      clientMessageId: clientMessageId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const String _eventId = 'evt-1';
const String _clientMessageId = '00000000-0000-4000-8000-000000000001';

Future<ChatOutboxEntry> _enqueueEntry(ChatOutboxStore store) async {
  await store.enqueueText(
    eventId: _eventId,
    tempId: 'temp-1',
    clientMessageId: _clientMessageId,
    body: 'hello',
  );
  final ChatOutboxEntry? entry = await store.peekNext(_eventId);
  expect(entry, isNotNull);
  return entry!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_outbox_sync_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    await ChatOutboxStore.shared.clearAll();
  });

  tearDown(() async {
    await ChatOutboxStore.shared.clearAll();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('retryDelayAfterAttempt delegates to shared backoff helper', () {
    expect(
      ChatOutboxSync.retryDelayAfterAttempt(0),
      const Duration(milliseconds: 200),
    );
    expect(ChatOutboxSync.retryDelayAfterAttempt(20).inMilliseconds, 30000);
  });

  test('flushOne sent removes row and returns saved message', () async {
    final ChatOutboxStore store = ChatOutboxStore.shared;
    final ChatOutboxEntry entry = await _enqueueEntry(store);
    final _FakeEventChatRepository repo = _FakeEventChatRepository();

    final ChatOutboxFlushResult result = await ChatOutboxSync.flushOne(
      repo: repo,
      store: store,
      entry: entry,
    );

    expect(result.kind, ChatOutboxFlushKind.sent);
    expect(result.savedMessage?.body, 'hello');
    expect(await store.listPending(_eventId), isEmpty);
  });

  test('flushOne retryable AppError keeps row pending', () async {
    final ChatOutboxStore store = ChatOutboxStore.shared;
    final ChatOutboxEntry entry = await _enqueueEntry(store);
    final _FakeEventChatRepository repo = _FakeEventChatRepository(
      onSend:
          (
            String eventId,
            String body, {
            String? replyToId,
            String? clientMessageId,
          }) async {
            throw AppError.network();
          },
    );

    final ChatOutboxFlushResult result = await ChatOutboxSync.flushOne(
      repo: repo,
      store: store,
      entry: entry,
    );

    expect(result.kind, ChatOutboxFlushKind.deferredRetryable);
    expect(result.savedMessage, isNull);
    final List<ChatOutboxEntry> pending = await store.listPending(_eventId);
    expect(pending, hasLength(1));
    expect(pending.single.attemptCount, 1);
    expect(pending.single.lastErrorCode, 'NETWORK_ERROR');
  });

  test('flushOne non-retryable AppError marks terminal failure', () async {
    final ChatOutboxStore store = ChatOutboxStore.shared;
    final ChatOutboxEntry entry = await _enqueueEntry(store);
    final _FakeEventChatRepository repo = _FakeEventChatRepository(
      onSend:
          (
            String eventId,
            String body, {
            String? replyToId,
            String? clientMessageId,
          }) async {
            throw AppError.validation(message: 'Blocked');
          },
    );

    final ChatOutboxFlushResult result = await ChatOutboxSync.flushOne(
      repo: repo,
      store: store,
      entry: entry,
    );

    expect(result.kind, ChatOutboxFlushKind.terminalFailed);
    expect(await store.listPending(_eventId), isEmpty);
    final List<ChatOutboxEntry> failed = await store.listPendingAndFailed(
      _eventId,
    );
    expect(failed, hasLength(1));
    expect(failed.single.isFailed, isTrue);
    expect(failed.single.lastErrorCode, 'VALIDATION_ERROR');
  });

  test('flushOne unknown error defers with UNKNOWN code', () async {
    final ChatOutboxStore store = ChatOutboxStore.shared;
    final ChatOutboxEntry entry = await _enqueueEntry(store);
    final _FakeEventChatRepository repo = _FakeEventChatRepository(
      onSend:
          (
            String eventId,
            String body, {
            String? replyToId,
            String? clientMessageId,
          }) async {
            throw StateError('unexpected');
          },
    );

    final ChatOutboxFlushResult result = await ChatOutboxSync.flushOne(
      repo: repo,
      store: store,
      entry: entry,
    );

    expect(result.kind, ChatOutboxFlushKind.deferredUnknown);
    final List<ChatOutboxEntry> pending = await store.listPending(_eventId);
    expect(pending, hasLength(1));
    expect(pending.single.attemptCount, 1);
    expect(pending.single.lastErrorCode, 'UNKNOWN');
  });
}
