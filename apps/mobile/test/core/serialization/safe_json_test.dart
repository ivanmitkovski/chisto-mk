import 'package:chisto_mobile/core/serialization/safe_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('safeJsonDecodeMap parses object', () {
    final Map<String, dynamic>? m =
        safeJsonDecodeMap('{"a":1}');
    expect(m?['a'], 1);
  });

  test('safeJsonDecodeMap returns null on invalid json', () {
    expect(safeJsonDecodeMap('not-json'), isNull);
  });

  test('safeAsList normalizes List', () {
    expect(safeAsList(<int>[1, 2])?.length, 2);
  });
}
