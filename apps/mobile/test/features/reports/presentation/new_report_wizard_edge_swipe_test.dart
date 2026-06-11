import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/application/report_wizard_submit_port.dart';
import 'package:feature_reports/src/application/reports_providers.dart';
import 'package:feature_reports/src/domain/models/report_upload_prep_progress.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_controller.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_wizard_state.dart';
import 'package:feature_reports/src/presentation/screens/new_report_wizard_view.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  ProviderContainer createContainer() {
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
    container.listen(newReportControllerProvider(null), (_, __) {});
    addTearDown(container.dispose);
    return container;
  }

  Widget wrapWizard({
    required ProviderContainer container,
    required NewReportController controller,
    required NewReportWizardState wizardState,
    required TextEditingController titleController,
    required TextEditingController descriptionController,
    required FocusNode titleFocus,
    required FocusNode descriptionFocus,
    required void Function(ReportStage stage, {bool unfocusFirst}) onGoToStage,
    required ValueNotifier<ReportUploadPrepProgress?> uploadPrepListenable,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: NewReportWizardView(
            controller: controller,
            wizardState: wizardState,
            entryLabel: null,
            entryHint: null,
            hasInitialPhoto: false,
            titleController: titleController,
            descriptionController: descriptionController,
            titleFocus: titleFocus,
            descriptionFocus: descriptionFocus,
            maxTitleLength: 80,
            maxDescriptionLength: 500,
            onAddPhoto: () async {},
            onPrimary: () {},
            onRetrySubmit: () async {},
            onGoToStage: onGoToStage,
            onScheduleDraftSave: () {},
            uploadPrepListenable: uploadPrepListenable,
            showDraftRestoredChip: false,
          ),
        ),
      ),
    );
  }

  testWidgets('includes EdgeSwipeBack on the wizard body', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = createContainer();
    final NewReportController controller = container.read(
      newReportControllerProvider(null).notifier,
    );
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final FocusNode titleFocus = FocusNode();
    final FocusNode descriptionFocus = FocusNode();
    final ValueNotifier<ReportUploadPrepProgress?> uploadPrepListenable =
        ValueNotifier<ReportUploadPrepProgress?>(null);
    addTearDown(titleController.dispose);
    addTearDown(descriptionController.dispose);
    addTearDown(titleFocus.dispose);
    addTearDown(descriptionFocus.dispose);
    addTearDown(uploadPrepListenable.dispose);

    await tester.pumpWidget(
      wrapWizard(
        container: container,
        controller: controller,
        wizardState: container.read(newReportControllerProvider(null)),
        titleController: titleController,
        descriptionController: descriptionController,
        titleFocus: titleFocus,
        descriptionFocus: descriptionFocus,
        onGoToStage: (_, {bool unfocusFirst = true}) {},
        uploadPrepListenable: uploadPrepListenable,
      ),
    );
    await tester.pump();

    expect(find.byType(EdgeSwipeBack), findsOneWidget);
  });
}
