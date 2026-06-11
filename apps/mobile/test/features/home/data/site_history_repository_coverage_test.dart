import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_home/src/data/site_history_repository.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: (_) {},
      );

  int getCalls = 0;
  final Map<String, ApiResponse> _responses = <String, ApiResponse>{};

  void stubGet(String path, ApiResponse response) {
    _responses[path] = response;
  }

  @override
  Future<ApiResponse> get(
    String path, {
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    getCalls += 1;
    final ApiResponse? response = _responses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }
}

Map<String, dynamic> _historyEntryJson() {
  return <String, dynamic>{
    'id': 'hist-1',
    'kind': 'STATUS_CHANGED',
    'occurredAt': '2026-03-01T12:00:00.000Z',
    'fromStatus': 'NEW',
    'toStatus': 'IN_REVIEW',
    'reportId': 'rep-1',
    'cleanupEventId': 'evt-1',
    'actor': <String, dynamic>{'displayName': 'Moderator', 'role': 'admin'},
    'note': 'Review started',
    'metadata': <String, dynamic>{'source': 'system'},
  };
}

void main() {
  test('fetchHistory throws validation error for empty site id', () async {
    final SiteHistoryRepository repo = SiteHistoryRepository(_FakeApiClient());

    await expectLater(
      repo.fetchHistory('  '),
      throwsA(
        predicate<AppError>(
          (AppError e) =>
              e.code == 'VALIDATION_ERROR' &&
              e.message.contains('Site id is required'),
        ),
      ),
    );
  });

  test('fetchHistory parses items and nextBeforeId', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/sites/site-1/history?limit=30',
      ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'items': <dynamic>[_historyEntryJson()],
          'nextBeforeId': 'hist-0',
        },
      ),
    );
    final SiteHistoryRepository repo = SiteHistoryRepository(client);

    final SiteHistoryPage page = await repo.fetchHistory('site-1');

    expect(client.getCalls, 1);
    expect(page.items, hasLength(1));
    final SiteHistoryEntry entry = page.items.single;
    expect(entry.id, 'hist-1');
    expect(entry.kind, SiteHistoryEntryKind.statusChanged);
    expect(
      entry.occurredAt,
      DateTime.parse('2026-03-01T12:00:00.000Z').toLocal(),
    );
    expect(entry.fromStatus, 'NEW');
    expect(entry.toStatus, 'IN_REVIEW');
    expect(entry.reportId, 'rep-1');
    expect(entry.cleanupEventId, 'evt-1');
    expect(entry.actorDisplayName, 'Moderator');
    expect(entry.actorRole, 'admin');
    expect(entry.note, 'Review started');
    expect(entry.metadata, <String, dynamic>{'source': 'system'});
    expect(page.nextBeforeId, 'hist-0');
  });

  test('fetchHistory parses summary when present', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/sites/site-1/history?limit=30',
      ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'items': <dynamic>[_historyEntryJson()],
          'nextBeforeId': null,
          'summary': <String, dynamic>{
            'totalEntries': 4,
            'reportCount': 2,
            'cleanupCount': 1,
            'currentStatus': 'VERIFIED',
            'firstActivityAt': '2026-01-01T00:00:00.000Z',
            'lastActivityAt': '2026-03-01T12:00:00.000Z',
          },
        },
      ),
    );
    final SiteHistoryRepository repo = SiteHistoryRepository(client);

    final SiteHistoryPage page = await repo.fetchHistory('site-1');

    expect(page.summary, isNotNull);
    expect(page.summary!.totalEntries, 4);
    expect(page.summary!.reportCount, 2);
    expect(page.summary!.cleanupCount, 1);
    expect(page.summary!.currentStatus, 'VERIFIED');
  });

  test('fetchHistory leaves summary null when absent', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/sites/site-1/history?limit=30',
      ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'items': <dynamic>[_historyEntryJson()],
          'nextBeforeId': null,
        },
      ),
    );
    final SiteHistoryRepository repo = SiteHistoryRepository(client);

    final SiteHistoryPage page = await repo.fetchHistory('site-1');
    expect(page.summary, isNull);
  });

  test('fetchHistory includes beforeId in query', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/sites/site-1/history?limit=10&beforeId=cursor-9',
      ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{'items': <dynamic>[], 'nextBeforeId': null},
      ),
    );
    final SiteHistoryRepository repo = SiteHistoryRepository(client);

    final SiteHistoryPage page = await repo.fetchHistory(
      'site-1',
      limit: 10,
      beforeId: 'cursor-9',
    );

    expect(client.getCalls, 1);
    expect(page.items, isEmpty);
    expect(page.nextBeforeId, isNull);
  });

  test('fetchHistory throws when response json is null', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/sites/site-1/history?limit=30',
      const ApiResponse(statusCode: 200),
    );
    final SiteHistoryRepository repo = SiteHistoryRepository(client);

    await expectLater(
      repo.fetchHistory('site-1'),
      throwsA(
        predicate<AppError>(
          (AppError e) =>
              e.code == 'UNKNOWN' &&
              e.cause == 'Missing site history response body',
        ),
      ),
    );
  });
}
