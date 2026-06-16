import 'package:feature_reports/src/presentation/widgets/new_report/report_severity_slider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('value 5 places thumb at the right travel end', () {
    const double width = 280;
    const int value = ReportSeveritySlider.max;
    const double fraction =
        (value - ReportSeveritySlider.min) /
        (ReportSeveritySlider.max - ReportSeveritySlider.min);
    const double travel = width - 2 * ReportSeveritySlider.thumbRadius;
    const double thumbCenterX =
        ReportSeveritySlider.thumbRadius + fraction * travel;
    expect(
      thumbCenterX,
      closeTo(width - ReportSeveritySlider.thumbRadius, 0.01),
    );
  });
}
