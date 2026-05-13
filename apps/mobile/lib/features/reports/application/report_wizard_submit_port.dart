import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_coordinator.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_upload_prep_progress.dart';

/// Presentation-facing port for wizard submit + upload prep (hides coordinator).
abstract class ReportWizardSubmitPort {
  ValueNotifier<ReportUploadPrepProgress?> get uploadPrepProgress;

  Future<ReportSubmitResult> submitReportAndAwait({
    required ReportDraft draft,
    required String title,
    required String description,
  });
}

final class ReportWizardSubmitPortImpl implements ReportWizardSubmitPort {
  ReportWizardSubmitPortImpl(this._coordinator);

  final ReportOutboxCoordinator _coordinator;

  @override
  ValueNotifier<ReportUploadPrepProgress?> get uploadPrepProgress =>
      _coordinator.uploadPrepProgress;

  @override
  Future<ReportSubmitResult> submitReportAndAwait({
    required ReportDraft draft,
    required String title,
    required String description,
  }) {
    return _coordinator.submitReportAndAwait(
      draft: draft,
      title: title,
      description: description,
    );
  }
}
