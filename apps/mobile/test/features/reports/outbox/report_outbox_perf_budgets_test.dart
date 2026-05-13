import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:flutter_test/flutter_test.dart';

/// Automated perf smoke: documents budgets and fails if constants regress to zero.
void main() {
  test('report outbox soft budgets are ordered and non-zero', () {
    expect(kReportDraftLoadTimeout.inMilliseconds, greaterThan(0));
    expect(kReportDraftRestoreBudget, kReportDraftLoadTimeout);
    expect(kReportUploadPrepBudgetPerPhotoSoft.inSeconds, greaterThanOrEqualTo(30));
    expect(kReportOutboxCoordinatorDrainSoftCap.inMinutes, greaterThanOrEqualTo(1));
  });
}
