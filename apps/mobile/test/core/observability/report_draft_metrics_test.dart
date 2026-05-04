import 'package:chisto_mobile/core/observability/report_draft_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ReportDraftMetrics.instance.resetForTest);

  test('recordPersistSuccess increments counter', () {
    expect(ReportDraftMetrics.instance.persistSuccessCount, 0);
    ReportDraftMetrics.instance.recordPersistSuccess();
    ReportDraftMetrics.instance.recordPersistSuccess();
    expect(ReportDraftMetrics.instance.persistSuccessCount, 2);
  });

  test('resetForTest clears counter', () {
    ReportDraftMetrics.instance.recordPersistSuccess();
    ReportDraftMetrics.instance.resetForTest();
    expect(ReportDraftMetrics.instance.persistSuccessCount, 0);
  });
}
