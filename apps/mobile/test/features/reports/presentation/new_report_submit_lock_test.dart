import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:feature_reports/src/application/report_wizard_submit_port.dart';
import 'package:feature_reports/src/application/reports_providers.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('tryBeginSubmit is false when wizardSubmitLocked', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        reportDraftRepositoryProvider.overrideWithValue(
          AppBootstrap.instance.reportDraftRepository,
        ),
        reportsApiRepositoryProvider.overrideWithValue(
          AppBootstrap.instance.reportsApiRepository,
        ),
        reportWizardSubmitPortProvider.overrideWithValue(
          AppBootstrap.instance.reportWizardSubmitPort,
        ),
      ],
    );
    addTearDown(container.dispose);

    final NewReportController controller = container.read(
      newReportControllerProvider(null).notifier,
    );
    controller.markSubmitSucceeded(
      const ReportSubmitResult(
        reportId: 'r-locked',
        siteId: 's1',
        isNewSite: false,
        pointsAwarded: 0,
      ),
    );

    expect(controller.wizardSubmitLocked, isTrue);
    expect(controller.tryBeginSubmit(), isFalse);
    expect(controller.submitting, isFalse);
  });
}
