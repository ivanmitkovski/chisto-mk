import 'dart:async';

import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/presentation/controllers/reports_list_controller.dart';

/// Bridges submit success from the new-report flow into the active [ReportsListController].
class ReportsListSession {
  Timer? _postSubmitRefresh;

  void onSubmitSucceeded({
    required ReportSubmitResult result,
    required String title,
    required ReportDraft draft,
  }) {
    readRoot(
      reportsListControllerProvider.notifier,
    ).insertOptimisticFromSubmit(result, title, draft);
    _schedulePostSubmitRefresh();
  }

  void _schedulePostSubmitRefresh() {
    _postSubmitRefresh?.cancel();
    _postSubmitRefresh = Timer(const Duration(seconds: 2), () {
      _postSubmitRefresh = null;
      unawaited(
        readRoot(reportsListControllerProvider.notifier).refreshFirstPage(),
      );
    });
  }
}
