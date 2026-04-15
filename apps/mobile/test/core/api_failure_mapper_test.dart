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
}
