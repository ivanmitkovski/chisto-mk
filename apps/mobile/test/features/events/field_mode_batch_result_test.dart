import 'package:chisto_mobile/features/events/data/field_mode_batch_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clears all row ids when failed is zero', () {
    expect(
      fieldModeRowIdsToClearAfterBatch(
        json: <String, dynamic>{'applied': 2, 'failed': 0},
        rowDbIdsInOperationOrder: <int?>[10, 11],
      ),
      <int>[10, 11],
    );
  });

  test('clears only non-failed indices when errors list present', () {
    expect(
      fieldModeRowIdsToClearAfterBatch(
        json: <String, dynamic>{
          'applied': 1,
          'failed': 1,
          'errors': <Map<String, Object?>>[
            <String, Object?>{'index': 0, 'code': 'X', 'message': 'm'},
          ],
        },
        rowDbIdsInOperationOrder: <int?>[10, 11],
      ),
      <int>[11],
    );
  });

  test('clears none when failed positive but errors missing', () {
    expect(
      fieldModeRowIdsToClearAfterBatch(
        json: <String, dynamic>{'applied': 0, 'failed': 1},
        rowDbIdsInOperationOrder: <int?>[10],
      ),
      isEmpty,
    );
  });
}
