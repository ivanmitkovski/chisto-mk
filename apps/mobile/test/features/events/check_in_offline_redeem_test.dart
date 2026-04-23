import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/check_in_offline_redeem.dart';
import 'package:chisto_mobile/features/events/data/check_in_sync_queue.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePostClient extends ApiClient {
  _FakePostClient()
      : super(
          config: AppConfig.dev,
          accessToken: () => null,
          onUnauthorized: () {},
        );

  Future<ApiResponse> Function(String path, Object? body)? postHandler;

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final Future<ApiResponse> Function(String path, Object? body)? h = postHandler;
    if (h == null) {
      throw StateError('post not stubbed');
    }
    return h(path, body);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryEventsStore events;
  late _FakePostClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    events = InMemoryEventsStore.instance;
    events.resetToSeed();
    client = _FakePostClient();
  });

  test('success removes queue entry and prefetches event', () async {
    const String payload = 'qr-success';
    await CheckInSyncQueue.instance.clear();
    await CheckInSyncQueue.instance.enqueue(
      CheckInQueueEntry(
        eventId: 'evt-1',
        qrPayload: payload,
        enqueuedAt: DateTime.now(),
      ),
    );

    client.postHandler = (String path, Object? body) async {
      expect(path, '/events/evt-1/check-in/redeem');
      return const ApiResponse(statusCode: 200, json: <String, dynamic>{});
    };

    await redeemOfflineCheckInEntry(
      client: client,
      eventsRepository: events,
      entry: CheckInQueueEntry(
        eventId: 'evt-1',
        qrPayload: payload,
        enqueuedAt: DateTime.now(),
      ),
    );

    expect(await CheckInSyncQueue.instance.peek(), isEmpty);
  });

  test('CHECK_IN_REPLAY removes queue entry without prefetch requirement', () async {
    const String payload = 'qr-replay';
    await CheckInSyncQueue.instance.clear();
    await CheckInSyncQueue.instance.enqueue(
      CheckInQueueEntry(
        eventId: 'evt-1',
        qrPayload: payload,
        enqueuedAt: DateTime.now(),
      ),
    );

    client.postHandler = (_, _) async {
      throw const AppError(code: 'CHECK_IN_REPLAY', message: 'used');
    };

    await redeemOfflineCheckInEntry(
      client: client,
      eventsRepository: events,
      entry: CheckInQueueEntry(
        eventId: 'evt-1',
        qrPayload: payload,
        enqueuedAt: DateTime.now(),
      ),
    );

    expect(await CheckInSyncQueue.instance.peek(), isEmpty);
  });

  test('network error leaves queue entry', () async {
    const String payload = 'qr-net';
    await CheckInSyncQueue.instance.clear();
    await CheckInSyncQueue.instance.enqueue(
      CheckInQueueEntry(
        eventId: 'evt-1',
        qrPayload: payload,
        enqueuedAt: DateTime.now(),
      ),
    );

    client.postHandler = (_, _) async {
      throw AppError.network();
    };

    expect(
      () => redeemOfflineCheckInEntry(
        client: client,
        eventsRepository: events,
        entry: CheckInQueueEntry(
          eventId: 'evt-1',
          qrPayload: payload,
          enqueuedAt: DateTime.now(),
        ),
      ),
      throwsA(isA<AppError>()),
    );

    final List<CheckInQueueEntry> remaining = await CheckInSyncQueue.instance.peek();
    expect(remaining, hasLength(1));
    expect(remaining.single.qrPayload, payload);
  });
}
