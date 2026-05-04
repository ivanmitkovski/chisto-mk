import 'package:chisto_mobile/features/reports/domain/draft/report_idempotency_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportIdempotencyKey', () {
    test('generate returns keys matching API shape', () {
      final Set<String> seen = <String>{};
      for (int i = 0; i < 24; i++) {
        final String k = ReportIdempotencyKey.generate();
        expect(ReportIdempotencyKey.isValidShape(k), isTrue, reason: k);
        expect(k.length, greaterThanOrEqualTo(16));
        expect(k.length, lessThanOrEqualTo(128));
        expect(seen.add(k), isTrue);
      }
    });

    test('isValidShape rejects short, long, and invalid characters', () {
      expect(ReportIdempotencyKey.isValidShape('123456789012345'), isFalse);
      expect(ReportIdempotencyKey.isValidShape('a' * 15), isFalse);
      expect(ReportIdempotencyKey.isValidShape('a' * 129), isFalse);
      expect(ReportIdempotencyKey.isValidShape('has space${'x' * 7}'), isFalse);
      expect(ReportIdempotencyKey.isValidShape('aaaaaaaaa${'é' * 7}'), isFalse);
    });

    test('isValidShape accepts boundary 16 and 128', () {
      expect(ReportIdempotencyKey.isValidShape('Abcdefghijklmn_0'), isTrue);
      expect(ReportIdempotencyKey.isValidShape('a' * 128), isTrue);
    });

    test('trims for isValidShape', () {
      expect(ReportIdempotencyKey.isValidShape('  ${'b' * 16}  '), isTrue);
    });
  });
}
