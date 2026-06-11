import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:feature_reports/src/application/report_wizard_submit_port.dart';
import 'package:feature_reports/src/application/reports_list_session.dart';
import 'package:feature_reports/src/application/reports_providers.dart';
import 'package:feature_reports/src/data/outbox/report_draft_repository.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/domain/models/report_upload_prep_progress.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_controller.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_submit_ui_flow.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_controller.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

class _ThrowingReportsListSession implements ReportsListSession {
  @override
  void onSubmitSucceeded({
    required ReportSubmitResult result,
    required String title,
    required ReportDraft draft,
  }) {
    throw StateError('post-success side effect failed');
  }
}

class _FakeSubmitPort implements ReportWizardSubmitPort {
  @override
  final ValueNotifier<ReportUploadPrepProgress?> uploadPrepProgress =
      ValueNotifier<ReportUploadPrepProgress?>(null);

  @override
  Future<ReportSubmitResult> submitReportAndAwait({
    required ReportDraft draft,
    required String title,
    required String description,
  }) async {
    return const ReportSubmitResult(
      reportId: 'r1',
      reportNumber: '42',
      siteId: 's1',
      pointsAwarded: 5,
      isNewSite: false,
    );
  }
}

class _NoClearDraftRepository implements ReportDraftRepository {
  bool clearCalled = false;

  @override
  Future<void> clear() async {
    clearCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets(
    'post-success side-effect failure does not surface submit apiError',
    (WidgetTester tester) async {
      final _NoClearDraftRepository draftRepo = _NoClearDraftRepository();

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          reportDraftRepositoryProvider.overrideWithValue(
            AppBootstrap.instance.reportDraftRepository,
          ),
          reportsApiRepositoryProvider.overrideWithValue(
            AppBootstrap.instance.reportsApiRepository,
          ),
          reportWizardSubmitPortProvider.overrideWithValue(_FakeSubmitPort()),
        ],
      );
      addTearDown(container.dispose);

      container.listen(newReportControllerProvider(null), (_, __) {});
      final NewReportController controller = container.read(
        newReportControllerProvider(null).notifier,
      );

      controller.updateTitle('Title');
      controller.updateDescription('Body');
      controller.updateCategory(ReportCategory.other);
      controller.updateSeverity(3);
      controller.onLocationChanged(
        const LocationPickerResult(
          latitude: 41.99,
          longitude: 21.43,
          address: 'Skopje',
          isInMacedonia: true,
        ),
      );
      for (final ReportStage stage in ReportStage.values) {
        controller.markStageAttempted(stage);
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () async {
                    final title = TextEditingController(text: 'Title');
                    final description = TextEditingController(text: 'Body');
                    await NewReportSubmitUiFlow.runSubmit(
                      context: context,
                      controller: controller,
                      titleController: title,
                      descriptionController: description,
                      bindings: NewReportSubmitBindings(
                        reportsListSession: _ThrowingReportsListSession(),
                        reportDraftRepository: draftRepo,
                      ),
                      onCannotSubmit: () {},
                    );
                    title.dispose();
                    description.dispose();
                  },
                  child: const Text('submit'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('submit'));
      await tester.pumpAndSettle();

      expect(controller.state.apiError, isNull);
      expect(controller.state.submitting, isFalse);
      expect(draftRepo.clearCalled, isFalse);
    },
  );
}
