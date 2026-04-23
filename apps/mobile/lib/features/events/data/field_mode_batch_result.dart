/// Parses `POST /events/field-batch` JSON and returns local SQLite row ids that
/// were successfully applied server-side (so they can be deleted locally).
///
/// When [json] reports `failed > 0`, successful operations are inferred by
/// excluding indices listed under `errors[].index`. If `errors` is missing in
/// that case, no rows are cleared (safe default).
List<int> fieldModeRowIdsToClearAfterBatch({
  required Map<String, dynamic> json,
  required List<int?> rowDbIdsInOperationOrder,
}) {
  final int failed = (json['failed'] as num?)?.toInt() ?? 0;
  if (failed <= 0) {
    return rowDbIdsInOperationOrder.whereType<int>().toList(growable: false);
  }
  final Object? rawErrors = json['errors'];
  if (rawErrors is! List) {
    return const <int>[];
  }
  final Set<int> failedIndices = <int>{};
  for (final Object? item in rawErrors) {
    if (item is Map) {
      final Object? idx = item['index'];
      if (idx is int) {
        failedIndices.add(idx);
      } else if (idx is num) {
        failedIndices.add(idx.toInt());
      }
    }
  }
  final List<int> out = <int>[];
  for (int i = 0; i < rowDbIdsInOperationOrder.length; i++) {
    if (!failedIndices.contains(i)) {
      final int? id = rowDbIdsInOperationOrder[i];
      if (id != null) {
        out.add(id);
      }
    }
  }
  return out;
}

/// Stable error codes per operation index from `errors[]` (for UI rows).
List<String?> fieldModeErrorCodesByOpIndex({
  required Map<String, dynamic> json,
  required int operationCount,
}) {
  if (operationCount <= 0) {
    return const <String?>[];
  }
  final List<String?> out = List<String?>.filled(operationCount, null);
  final Object? rawErrors = json['errors'];
  if (rawErrors is! List<Object?>) {
    return out;
  }
  for (final Object? item in rawErrors) {
    if (item is! Map) {
      continue;
    }
    final Object? idxRaw = item['index'];
    int? idx;
    if (idxRaw is int) {
      idx = idxRaw;
    } else if (idxRaw is num) {
      idx = idxRaw.toInt();
    }
    if (idx == null || idx < 0 || idx >= operationCount) {
      continue;
    }
    final Object? codeRaw = item['code'];
    out[idx] = codeRaw is String && codeRaw.trim().isNotEmpty ? codeRaw.trim() : 'UNKNOWN';
  }
  return out;
}
