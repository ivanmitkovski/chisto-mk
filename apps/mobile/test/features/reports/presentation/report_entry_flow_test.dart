import 'package:feature_reports/src/presentation/flow/report_entry_flow.dart';
import 'package:feature_reports/src/presentation/navigation/new_report_wizard_pop_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('handleNewReportWizardPopResult opens report by id', () {
    String? openedId;
    var listOpened = false;

    ReportEntryFlow.handleNewReportWizardPopResult(
      const NewReportWizardViewReport('report-abc'),
      onViewSubmittedReport: (String id) => openedId = id,
      onViewReportsList: () => listOpened = true,
    );

    expect(openedId, 'report-abc');
    expect(listOpened, isFalse);
  });

  test('handleNewReportWizardPopResult opens reports list', () {
    String? openedId;
    var listOpened = false;

    ReportEntryFlow.handleNewReportWizardPopResult(
      const NewReportWizardViewReports(),
      onViewSubmittedReport: (String id) => openedId = id,
      onViewReportsList: () => listOpened = true,
    );

    expect(openedId, isNull);
    expect(listOpened, isTrue);
  });

  test('handleNewReportWizardPopResult ignores report another', () {
    var called = false;

    ReportEntryFlow.handleNewReportWizardPopResult(
      const NewReportWizardReportAnother(),
      onViewSubmittedReport: (_) => called = true,
      onViewReportsList: () => called = true,
    );

    expect(called, isFalse);
  });
}
