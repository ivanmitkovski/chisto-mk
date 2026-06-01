import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_networking/chisto_networking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appErrorFromFailedResponse status mapping', () {
    test('403 maps to non-retryable error with API code', () {
      final AppError err = appErrorFromFailedResponse(
        statusCode: 403,
        json: <String, dynamic>{
          'code': 'ACCOUNT_SUSPENDED',
          'message': 'Account suspended',
        },
      );
      expect(err.code, 'ACCOUNT_SUSPENDED');
      expect(err.retryable, isFalse);
    });

    test('500 maps to AppError.server', () {
      final AppError err = appErrorFromFailedResponse(
        statusCode: 503,
        json: <String, dynamic>{'message': 'Service unavailable'},
      );
      expect(err.code, 'SERVER_ERROR');
      expect(err.retryable, isTrue);
    });

    test('408 maps to AppError.timeout', () {
      final AppError err = appErrorFromFailedResponse(
        statusCode: 408,
        json: <String, dynamic>{'message': 'Request timeout'},
      );
      expect(err.code, 'TIMEOUT');
    });

    test('400 with VALIDATION_ERROR code maps to validation error', () {
      final AppError err = appErrorFromFailedResponse(
        statusCode: 400,
        json: <String, dynamic>{
          'code': 'VALIDATION_ERROR',
          'message': 'Invalid payload',
          'details': <String, dynamic>{'field': 'title'},
        },
      );
      expect(err.code, 'VALIDATION_ERROR');
      expect(err.details, isA<Map<String, dynamic>>());
    });

    test('429 merges retryAfterSeconds from JSON and header', () {
      final AppError fromJson = appErrorFromFailedResponse(
        statusCode: 429,
        json: <String, dynamic>{
          'message': 'Slow down',
          'retryAfterSeconds': 30,
        },
      );
      expect(fromJson.code, 'TOO_MANY_REQUESTS');
      expect(fromJson.retryable, isTrue);
      expect(fromJson.details?['retryAfterSeconds'], 30);

      final AppError fromHeader = appErrorFromFailedResponse(
        statusCode: 429,
        json: <String, dynamic>{'message': 'Slow down'},
        retryAfterHeader: '45',
      );
      expect(fromHeader.details?['retryAfterSeconds'], 45);
    });

    test(
      '401 without retryable flag is retryable when retryAfterSeconds present',
      () {
        final AppError err = appErrorFromFailedResponse(
          statusCode: 401,
          json: <String, dynamic>{
            'code': 'UNAUTHORIZED',
            'message': 'Try again later',
            'retryAfterSeconds': 60,
          },
        );
        expect(err.retryable, isTrue);
        expect(err.details?['retryAfterSeconds'], 60);
      },
    );

    test('falls back to bodyStr message when JSON message absent', () {
      final AppError err = appErrorFromFailedResponse(
        statusCode: 502,
        bodyStr: 'Bad gateway',
      );
      expect(err.message, 'Bad gateway');
      expect(err.code, 'SERVER_ERROR');
    });
  });
}
