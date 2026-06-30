import 'package:feature_events/src/data/check_in_redeem_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redeemResponseCheckedInAt reads root and nested data', () {
    expect(
      redeemResponseCheckedInAt(<String, dynamic>{
        'checkedInAt': '2026-06-15T13:01:00.000Z',
      }),
      isNotNull,
    );
    expect(
      redeemResponseCheckedInAt(<String, dynamic>{
        'data': <String, dynamic>{'checkedInAt': '2026-06-15T13:01:00.000Z'},
      }),
      isNotNull,
    );
    expect(redeemResponseCheckedInAt(<String, dynamic>{}), isNull);
  });

  test('redeemResponseIsPendingConfirmation detects status', () {
    expect(
      redeemResponseIsPendingConfirmation(<String, dynamic>{
        'status': 'pending_confirmation',
      }),
      isTrue,
    );
    expect(
      redeemResponseIsPendingConfirmation(<String, dynamic>{
        'status': 'success',
      }),
      isFalse,
    );
  });
}
