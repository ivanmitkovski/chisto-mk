import 'dart:convert';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/field_mode_batch_result.dart';
import 'package:chisto_mobile/features/events/data/field_mode_queue.dart';

/// Result of attempting to sync the SQLite field queue to `POST /events/field-batch`.
class FieldModeSyncResult {
  const FieldModeSyncResult._({
    required this.hadOperations,
    required this.httpOk,
    required this.applied,
    required this.failed,
    required this.clearedRowIds,
    this.statusCode,
    this.error,
    this.errorCodesByOperationIndex = const <String>[],
  });

  /// Nothing to send (empty queue or no decodable operations).
  factory FieldModeSyncResult.empty() => const FieldModeSyncResult._(
        hadOperations: false,
        httpOk: true,
        applied: 0,
        failed: 0,
        clearedRowIds: <int>[],
        errorCodesByOperationIndex: <String>[],
      );

  final bool hadOperations;
  final bool httpOk;
  final int applied;
  final int failed;
  final List<int> clearedRowIds;
  final int? statusCode;
  final Object? error;

  /// Parallel to the batch operation list: non-empty string means that index failed (server code).
  final List<String> errorCodesByOperationIndex;

  bool get clearedAny => clearedRowIds.isNotEmpty;
}

/// Builds the batch payload from raw SQLite rows (shared by UI and background sync).
FieldModeBatchBuildResult buildFieldBatchFromQueueRows(List<Map<String, Object?>> rows) {
  final List<Map<String, dynamic>> operations = <Map<String, dynamic>>[];
  final List<int?> rowIdsInOpOrder = <int?>[];
  for (final Map<String, Object?> row in rows) {
    final String? raw = row['op'] as String?;
    if (raw == null) {
      continue;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        operations.add(decoded);
        rowIdsInOpOrder.add(row['id'] as int?);
      }
    } on Object {
      // skip malformed row
    }
  }
  return FieldModeBatchBuildResult(
    operations: operations,
    rowIdsInOpOrder: rowIdsInOpOrder,
  );
}

class FieldModeBatchBuildResult {
  const FieldModeBatchBuildResult({
    required this.operations,
    required this.rowIdsInOpOrder,
  });

  final List<Map<String, dynamic>> operations;
  final List<int?> rowIdsInOpOrder;

  bool get isEmpty => operations.isEmpty;
}

/// Applies queued field operations via the API and clears successful SQLite rows.
class FieldModeSyncService {
  FieldModeSyncService({
    required ApiClient client,
    FieldModeQueue? queue,
  })  : _client = client,
        _queue = queue ?? FieldModeQueue.instance;

  final ApiClient _client;
  final FieldModeQueue _queue;

  /// Reads the queue, POSTs `/events/field-batch`, clears applied rows. Does not throw on HTTP errors.
  Future<FieldModeSyncResult> syncPendingRows() async {
    final List<Map<String, Object?>> rows = await _queue.pendingRows();
    final FieldModeBatchBuildResult built = buildFieldBatchFromQueueRows(rows);
    if (built.isEmpty) {
      return FieldModeSyncResult.empty();
    }
    try {
      final ApiResponse res = await _client.post(
        '/events/field-batch',
        body: <String, dynamic>{'operations': built.operations},
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return FieldModeSyncResult._(
          hadOperations: true,
          httpOk: false,
          applied: 0,
          failed: built.operations.length,
          clearedRowIds: const <int>[],
          statusCode: res.statusCode,
          errorCodesByOperationIndex: List<String>.filled(
            built.operations.length,
            'HTTP_${res.statusCode}',
          ),
        );
      }
      final Map<String, dynamic>? json = res.json;
      if (json == null) {
        final List<int> ids = built.rowIdsInOpOrder.whereType<int>().toList(growable: false);
        await _queue.clearIds(ids);
        return FieldModeSyncResult._(
          hadOperations: true,
          httpOk: true,
          applied: built.operations.length,
          failed: 0,
          clearedRowIds: ids,
          statusCode: res.statusCode,
          errorCodesByOperationIndex: List<String>.filled(built.operations.length, ''),
        );
      }
      final List<int> idsToClear = fieldModeRowIdsToClearAfterBatch(
        json: json,
        rowDbIdsInOperationOrder: built.rowIdsInOpOrder,
      );
      await _queue.clearIds(idsToClear);
      final int failed = (json['failed'] as num?)?.toInt() ?? 0;
      final int applied = (json['applied'] as num?)?.toInt() ?? 0;
      final List<String?> byIdx = fieldModeErrorCodesByOpIndex(
        json: json,
        operationCount: built.operations.length,
      );
      final List<String> codes = List<String>.generate(
        built.operations.length,
        (int i) => (byIdx.length > i ? byIdx[i] : null)?.trim() ?? '',
      );
      return FieldModeSyncResult._(
        hadOperations: true,
        httpOk: true,
        applied: applied,
        failed: failed,
        clearedRowIds: idsToClear,
        statusCode: res.statusCode,
        errorCodesByOperationIndex: codes,
      );
    } on AppError catch (e) {
      return FieldModeSyncResult._(
        hadOperations: true,
        httpOk: false,
        applied: 0,
        failed: built.operations.length,
        clearedRowIds: const <int>[],
        error: e,
        errorCodesByOperationIndex: List<String>.filled(
          built.operations.length,
          e.code,
        ),
      );
    } on Object catch (e) {
      return FieldModeSyncResult._(
        hadOperations: true,
        httpOk: false,
        applied: 0,
        failed: built.operations.length,
        clearedRowIds: const <int>[],
        error: e,
        errorCodesByOperationIndex: List<String>.filled(
          built.operations.length,
          'UNKNOWN',
        ),
      );
    }
  }
}
