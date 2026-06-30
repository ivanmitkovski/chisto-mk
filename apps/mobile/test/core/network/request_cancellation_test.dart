import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_networking/chisto_networking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestCancellationToken', () {
    test('starts uncancelled', () {
      final RequestCancellationToken token = RequestCancellationToken();
      expect(token.isCancelled, isFalse);
      expect(token.throwIfCancelled, returnsNormally);
    });

    test('cancel marks token and throwIfCancelled raises AppError', () {
      final RequestCancellationToken token = RequestCancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
      expect(
        token.throwIfCancelled,
        throwsA(
          isA<AppError>().having((AppError e) => e.code, 'code', 'CANCELLED'),
        ),
      );
    });

    test('cancel is idempotent', () {
      final RequestCancellationToken token = RequestCancellationToken();
      token.cancel();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });
  });
}
