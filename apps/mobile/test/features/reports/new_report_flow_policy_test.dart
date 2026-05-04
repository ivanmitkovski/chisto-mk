import 'package:flutter_test/flutter_test.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/draft/new_report_flow_policy.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';

void main() {
  group('NewReportFlowPolicy', () {
    test('firstBlockingStage returns evidence when no photos', () {
      expect(
        NewReportFlowPolicy.firstBlockingStage(ReportDraft()),
        ReportStage.evidence,
      );
    });

    test('hasValidLocation false for empty draft', () {
      expect(NewReportFlowPolicy.hasValidLocation(ReportDraft()), false);
    });

    test('canNavigateToStage allows backward from review to evidence', () {
      final ReportDraft d = ReportDraft();
      expect(
        NewReportFlowPolicy.canNavigateToStage(
          target: ReportStage.evidence,
          current: ReportStage.review,
          draft: d,
        ),
        true,
      );
    });

    test(
      'canNavigateToStage blocks jumping to location without prior steps',
      () {
        final ReportDraft d = ReportDraft();
        expect(
          NewReportFlowPolicy.canNavigateToStage(
            target: ReportStage.location,
            current: ReportStage.evidence,
            draft: d,
          ),
          false,
        );
      },
    );
  });
}
