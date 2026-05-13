import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_error_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyReportSubmitError', () {
    test('cooldown', () {
      expect(
        classifyReportSubmitError(
          AppError(code: 'REPORTING_COOLDOWN', message: 'x'),
        ),
        ReportOutboxErrorKind.cooldown,
      );
    });

    test('retryable by code', () {
      expect(
        classifyReportSubmitError(
          AppError(code: 'NETWORK_ERROR', message: 'x'),
        ),
        ReportOutboxErrorKind.retryable,
      );
    });

    test('terminal default', () {
      expect(
        classifyReportSubmitError(
          AppError(code: 'VALIDATION_ERROR', message: 'x', retryable: false),
        ),
        ReportOutboxErrorKind.terminal,
      );
    });
  });

  group('backoffMsForAttempt', () {
    test('increases with attempt', () {
      expect(backoffMsForAttempt(1), lessThan(backoffMsForAttempt(3)));
    });

    test('clamps to attempt 8 and cap', () {
      final int high = backoffMsForAttempt(99);
      expect(high, lessThanOrEqualTo(5 * 60 * 1000 + (5 * 60 * 1000 * 0.15).ceil()));
      expect(high, greaterThanOrEqualTo(5 * 60 * 1000 - (5 * 60 * 1000 * 0.15).ceil()));
    });

    test('attempt 0 is clamped to tier 1 like attempt 1 (jittered range)', () {
      const int ms = 2000;
      final int jitter = (ms * 0.15).round();
      final int lo = ms - jitter;
      final int hi = ms + jitter;
      expect(backoffMsForAttempt(0), inInclusiveRange(lo, hi));
      expect(backoffMsForAttempt(1), inInclusiveRange(lo, hi));
    });
  });

  group('retryable codes', () {
    test('TIMEOUT', () {
      expect(
        classifyReportSubmitError(
          AppError(code: 'TIMEOUT', message: 'x', retryable: true),
        ),
        ReportOutboxErrorKind.retryable,
      );
    });

    test('SERVER_ERROR', () {
      expect(
        classifyReportSubmitError(AppError.server()),
        ReportOutboxErrorKind.retryable,
      );
    });

    test('TOO_MANY_REQUESTS', () {
      expect(
        classifyReportSubmitError(AppError.tooManyRequests()),
        ReportOutboxErrorKind.retryable,
      );
    });

    test('generic retryable flag', () {
      expect(
        classifyReportSubmitError(
          AppError(code: 'CUSTOM', message: 'x', retryable: true),
        ),
        ReportOutboxErrorKind.retryable,
      );
    });
  });

  group('cooldownUntilMsFromAppError', () {
    test('null when not cooldown', () {
      expect(cooldownUntilMsFromAppError(AppError.server()), isNull);
    });

    test('malformed details defaults to ~60s ahead', () {
      final int? until = cooldownUntilMsFromAppError(
        AppError(
          code: 'REPORTING_COOLDOWN',
          message: 'x',
          details: 'not-a-map',
        ),
      );
      expect(until, isNotNull);
      expect(
        until! - DateTime.now().millisecondsSinceEpoch,
        inInclusiveRange(59 * 1000, 61 * 1000),
      );
    });

    test('retryAfterSeconds', () {
      final int? until = cooldownUntilMsFromAppError(
        AppError(
          code: 'REPORTING_COOLDOWN',
          message: 'x',
          details: <String, dynamic>{'retryAfterSeconds': 42},
        ),
      );
      expect(until, isNotNull);
      expect(
        until! - DateTime.now().millisecondsSinceEpoch,
        inInclusiveRange(41 * 1000, 43 * 1000),
      );
    });

    test('nextEmergencyReportAvailableAt', () {
      final DateTime t = DateTime.now().toUtc().add(const Duration(minutes: 5));
      final int? until = cooldownUntilMsFromAppError(
        AppError(
          code: 'REPORTING_COOLDOWN',
          message: 'x',
          details: <String, dynamic>{
            'nextEmergencyReportAvailableAt': t.toIso8601String(),
          },
        ),
      );
      expect(until, t.millisecondsSinceEpoch);
    });
  });
}
