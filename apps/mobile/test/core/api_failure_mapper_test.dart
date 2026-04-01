import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_failure_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appErrorFromFailedResponse', () {
    test('429 maps to TOO_MANY_REQUESTS with retryable', () {
      final AppError e = appErrorFromFailedResponse(
        statusCode: 429,
        json: <String, dynamic>{
          'code': 'TOO_MANY_REQUESTS',
          'message': 'Slow down',
          'retryAfterSeconds': 45,
        },
        bodyStr: null,
        retryAfterHeader: null,
      );
      expect(e.code, 'TOO_MANY_REQUESTS');
      expect(e.retryable, isTrue);
      expect(e.message, 'Slow down');
      expect(e.details, <String, dynamic>{'retryAfterSeconds': 45});
    });

    test('429 uses Retry-After header seconds when JSON omits retryAfterSeconds', () {
      final AppError e = appErrorFromFailedResponse(
        statusCode: 429,
        json: null,
        bodyStr: 'Too Many Requests',
        retryAfterHeader: '120',
      );
      expect(e.code, 'TOO_MANY_REQUESTS');
      expect(e.details, <String, dynamic>{'retryAfterSeconds': 120});
    });

    test('401 returns error without side effects', () {
      final AppError e = appErrorFromFailedResponse(
        statusCode: 401,
        json: <String, dynamic>{
          'code': 'INVALID_CREDENTIALS',
          'message': 'Nope',
        },
        bodyStr: null,
        retryAfterHeader: null,
      );
      expect(e.code, 'INVALID_CREDENTIALS');
      expect(e.message, 'Nope');
    });

    test('422 maps to validation', () {
      final AppError e = appErrorFromFailedResponse(
        statusCode: 422,
        json: <String, dynamic>{
          'code': 'VALIDATION_ERROR',
          'message': 'Invalid',
          'details': <String>['x'],
        },
        bodyStr: null,
        retryAfterHeader: null,
      );
      expect(e.code, 'VALIDATION_ERROR');
      expect(e.details, <String>['x']);
    });
  });
}
