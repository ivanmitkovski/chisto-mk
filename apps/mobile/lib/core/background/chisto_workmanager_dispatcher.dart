import 'package:workmanager/workmanager.dart';

import 'package:chisto_mobile/features/home/data/offline_regions/offline_refresh_dispatcher.dart';
import 'package:chisto_mobile/features/reports/data/outbox/background/report_outbox_background_drain.dart';

/// Single [Workmanager] entrypoint for all background Dart tasks.
///
/// Must remain a top-level function with [pragma] so Android/iOS can link the
/// background isolate. Route new tasks by [task] / unique name in
/// [ReportOutboxBackgroundDrain] and [OfflineRefreshDispatcher].
@pragma('vm:entry-point')
void chistoWorkmanagerCallbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    if (task == OfflineRefreshDispatcher.taskName) {
      return OfflineRefreshDispatcher.runRefreshSavedRegions();
    }
    if (task == ReportOutboxBackgroundDrain.taskName ||
        task == ReportOutboxBackgroundDrain.uniqueTaskName) {
      return ReportOutboxBackgroundDrain.run();
    }
    return false;
  });
}
