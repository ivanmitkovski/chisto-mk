import 'package:flutter_test/flutter_test.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_failure_mapper.dart';

void main() {
  test('appErrorFromFailedResponse parses ISO timestamp from API JSON', () {
    final AppError err = appErrorFromFailedResponse(
      statusCode: 400,
      json: <String, dynamic>{
        'code': 'BAD_REQUEST',
        'message': 'Invalid input',
        'timestamp': '2026-04-14T12:34:56.000Z',
      },
      bodyStr: null,
      retryAfterHeader: null,
    );
    expect(err.serverTimestamp, isNotNull);
    expect(err.serverTimestamp!.toUtc().year, 2026);
    expect(err.serverTimestamp!.toUtc().month, 4);
    expect(err.serverTimestamp!.toUtc().day, 14);
  });

  test('appErrorFromFailedResponse leaves serverTimestamp null when absent', () {
    final AppError err = appErrorFromFailedResponse(
      statusCode: 404,
      json: <String, dynamic>{
        'code': 'NOT_FOUND',
        'message': 'Missing',
      },
      bodyStr: null,
      retryAfterHeader: null,
    );
    expect(err.serverTimestamp, isNull);
  });

  test('422 maps to AppError.validation with stable VALIDATION_ERROR code', () {
    final AppError err = appErrorFromFailedResponse(
      statusCode: 422,
      json: <String, dynamic>{
        'code': 'SOME_SERVER_CODE',
        'message': 'Title is required',
        'details': <String, dynamic>{'field': 'title'},
      },
      bodyStr: null,
      retryAfterHeader: null,
    );
    expect(err.code, 'VALIDATION_ERROR');
    expect(err.message, 'Title is required');
    expect(err.details, isA<Map<String, dynamic>>());
  });

  test('appErrorFromFailedResponse merges API details for 429', () {
    final AppError err = appErrorFromFailedResponse(
      statusCode: 429,
      json: <String, dynamic>{
        'code': 'MAP_RATE_LIMITED',
        'message': 'Too many map requests',
        'details': <String, dynamic>{'ttlSeconds': 60, 'limit': 480, 'mode': 'redis'},
      },
      bodyStr: null,
      retryAfterHeader: null,
    );
    expect(err.code, 'TOO_MANY_REQUESTS');
    expect(err.details, isA<Map<String, dynamic>>());
    final Map<String, dynamic> d = err.details! as Map<String, dynamic>;
    expect(d['ttlSeconds'], 60);
    expect(d['limit'], 480);
  });
}
