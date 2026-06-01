import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_failure_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('401 TOO_MANY_ATTEMPTS includes retryAfterSeconds in details', () {
    final AppError err = appErrorFromFailedResponse(
      statusCode: 401,
      json: <String, dynamic>{
        'code': 'TOO_MANY_ATTEMPTS',
        'message': 'Too many failed attempts',
        'retryable': true,
        'retryAfterSeconds': 120,
      },
    );
    expect(err.code, 'TOO_MANY_ATTEMPTS');
    expect(err.retryable, isTrue);
    expect(err.details?['retryAfterSeconds'], 120);
  });
}
