import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/reports_list_controller.dart';

/// Bridges submit success from the new-report flow into the active [ReportsListController].
///
/// The list screen [attach]s on init and [detach]es on dispose so other routes never
/// touch a stale controller reference.
class ReportsListSession {
  ReportsListController? _controller;

  void attach(ReportsListController controller) {
    _controller = controller;
  }

  void detach(ReportsListController controller) {
    if (identical(_controller, controller)) {
      _controller = null;
    }
  }

  void onSubmitSucceeded({
    required ReportSubmitResult result,
    required String title,
    required ReportDraft draft,
  }) {
    _controller?.insertOptimisticFromSubmit(result, title, draft);
  }
}
