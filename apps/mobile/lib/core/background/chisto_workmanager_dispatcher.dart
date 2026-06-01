import 'package:feature_reports/src/data/outbox/background/report_outbox_background_drain.dart';
import 'package:workmanager/workmanager.dart';

/// Single [Workmanager] entrypoint for all background Dart tasks.
///
/// Must remain a top-level function with [pragma] so Android/iOS can link the
/// background isolate. Route new tasks by [task] / unique name in
/// [ReportOutboxBackgroundDrain].
@pragma('vm:entry-point')
void chistoWorkmanagerCallbackDispatcher() {
  Workmanager().executeTask((
    String task,
    Map<String, dynamic>? inputData,
  ) async {
    if (task == ReportOutboxBackgroundDrain.taskName ||
        task == ReportOutboxBackgroundDrain.uniqueTaskName) {
      return ReportOutboxBackgroundDrain.run();
    }
    return false;
  });
}
