import 'dart:convert';
import 'dart:io';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/field_mode_batch_result.dart';
import 'package:chisto_mobile/features/events/data/field_mode_queue.dart';
import 'package:chisto_mobile/features/events/data/field_mode_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

class _StubFieldBatchApiClient extends ApiClient {
  _StubFieldBatchApiClient()
      : super(
          config: AppConfig.dev,
          accessToken: () => null,
          onUnauthorized: () {},
        );

  Future<ApiResponse> Function(String path, Object? body)? onPost;

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final Future<ApiResponse> Function(String path, Object? body)? fn = onPost;
    if (fn == null) {
      throw StateError('onPost not stubbed');
    }
    return fn(path, body);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await FieldModeQueue.instance.closeDatabase();
    tempDir = await Directory.systemTemp.createTemp('field_mode_sync_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    final List<Map<String, Object?>> rows = await FieldModeQueue.instance.pendingRows();
    final List<int> ids = rows
        .map((Map<String, Object?> r) => r['id'] as int?)
        .whereType<int>()
        .toList();
    await FieldModeQueue.instance.clearIds(ids);
  });

  tearDown(() async {
    await FieldModeQueue.instance.closeDatabase();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('buildFieldBatchFromQueueRows skips invalid JSON and preserves op order', () {
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[
      <String, Object?>{
        'id': 1,
        'op': jsonEncode(<String, dynamic>{'type': 'live_impact_bags', 'eventId': 'e1'}),
      },
      <String, Object?>{'id': 2, 'op': 'not-json'},
      <String, Object?>{
        'id': 3,
        'op': jsonEncode(<String, dynamic>{'type': 'live_impact_bags', 'eventId': 'e2'}),
      },
    ];
    final FieldModeBatchBuildResult built = buildFieldBatchFromQueueRows(rows);
    expect(built.operations.length, 2);
    expect(built.rowIdsInOpOrder, <int?>[1, 3]);
  });

  test('fieldModeRowIdsToClearAfterBatch excludes failed indices', () {
    final List<int?> rowIds = <int?>[10, 11, 12];
    final List<int> cleared = fieldModeRowIdsToClearAfterBatch(
      json: <String, dynamic>{
        'applied': 2,
        'failed': 1,
        'errors': <Map<String, Object?>>[
          <String, Object?>{'index': 1},
        ],
      },
      rowDbIdsInOperationOrder: rowIds,
    );
    expect(cleared, <int>[10, 12]);
  });

  test('syncPendingRows clears only successful rows on partial API failure', () async {
    await FieldModeQueue.instance.enqueueLiveImpactBags(eventId: 'ev1', reportedBagsCollected: 1);
    await FieldModeQueue.instance.enqueueLiveImpactBags(eventId: 'ev1', reportedBagsCollected: 2);
    final List<Map<String, Object?>> rowsBefore = await FieldModeQueue.instance.pendingRows();
    expect(rowsBefore.length, 2);

    final _StubFieldBatchApiClient client = _StubFieldBatchApiClient();
    client.onPost = (String path, Object? body) async {
      expect(path, '/events/field-batch');
      return ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'applied': 1,
          'failed': 1,
          'errors': <Map<String, Object?>>[
            <String, Object?>{'index': 0, 'code': 'ROUTE_SEGMENT_NOT_CLAIMABLE'},
          ],
        },
      );
    };

    final FieldModeSyncService sync = FieldModeSyncService(client: client);
    final FieldModeSyncResult result = await sync.syncPendingRows();

    expect(result.hadOperations, isTrue);
    expect(result.httpOk, isTrue);
    expect(result.failed, 1);
    expect(result.applied, 1);
    expect(result.errorCodesByOperationIndex.length, 2);
    expect(result.errorCodesByOperationIndex[0], 'ROUTE_SEGMENT_NOT_CLAIMABLE');
    expect(result.errorCodesByOperationIndex[1], isEmpty);

    final List<Map<String, Object?>> rowsAfter = await FieldModeQueue.instance.pendingRows();
    expect(rowsAfter.length, 1);
    final String? op = rowsAfter.first['op'] as String?;
    expect(op, isNotNull);
    final Object? decoded = jsonDecode(op!);
    expect(decoded, isA<Map<String, dynamic>>());
    expect((decoded as Map<String, dynamic>)['reportedBagsCollected'], 1);
  });
}
