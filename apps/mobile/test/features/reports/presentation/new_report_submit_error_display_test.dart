import 'dart:io';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_submit_error_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NewReportSubmitErrorDisplay', () {
    test('UNKNOWN maps to SUBMIT_FAILED_RETRYABLE without English message', () {
      final AppError wrapped = AppError.unknown(
        cause: const SocketException('Connection refused'),
      );

      final AppError banner =
          NewReportSubmitErrorDisplay.humanizeSubmitErrorForBanner(wrapped);

      expect(banner.code, 'SUBMIT_FAILED_RETRYABLE');
      expect(banner.retryable, isTrue);
      expect(banner.message, isEmpty);
    });

    test('NETWORK_ERROR passes through unchanged', () {
      final AppError network = AppError.network(
        message: 'Unable to reach the server. Check your connection.',
      );

      expect(
        NewReportSubmitErrorDisplay.humanizeSubmitErrorForBanner(network),
        same(network),
      );
    });

    test('bare UNKNOWN uses retryable code without message', () {
      final AppError unknown = AppError.unknown();

      final AppError banner =
          NewReportSubmitErrorDisplay.humanizeSubmitErrorForBanner(unknown);

      expect(banner.code, 'SUBMIT_FAILED_RETRYABLE');
      expect(banner.message, isEmpty);
    });
  });
}
