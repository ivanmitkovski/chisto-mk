import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/events/data/check_in_redeem_queue_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('terminal conflict codes drop queue entry', () {
    const List<String> codes = <String>[
      'CHECK_IN_REPLAY',
      'CHECK_IN_ALREADY_CHECKED_IN',
      'CHECK_IN_ALREADY_RECORDED',
      'CONFLICT',
      'CHECK_IN_QR_EXPIRED',
      'CHECK_IN_SESSION_MISMATCH',
      'CHECK_IN_INVALID_QR',
      'CHECK_IN_WRONG_EVENT',
    ];
    for (final String code in codes) {
      expect(
        shouldRemoveQueuedCheckInAfterRedeemError(AppError(code: code, message: 'x')),
        isTrue,
        reason: code,
      );
    }
  });

  test('retryable client errors keep queue entry', () {
    expect(
      shouldRemoveQueuedCheckInAfterRedeemError(
        AppError.network(message: 'offline'),
      ),
      isFalse,
    );
    expect(
      shouldRemoveQueuedCheckInAfterRedeemError(
        const AppError(code: 'CHECK_IN_REQUIRES_JOIN', message: 'join first'),
      ),
      isFalse,
    );
  });
}
