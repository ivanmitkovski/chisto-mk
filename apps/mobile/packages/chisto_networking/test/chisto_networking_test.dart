import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_networking/chisto_networking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('request cancellation throws AppError.cancelled', () {
    final RequestCancellationToken token = RequestCancellationToken();
    token.cancel();
    expect(token.isCancelled, isTrue);
    expect(token.throwIfCancelled, throwsA(isA<AppError>()));
  });

  test('maps 404 to not found', () {
    final AppError error = appErrorFromFailedResponse(statusCode: 404);
    expect(error.code, 'NOT_FOUND');
  });
}
