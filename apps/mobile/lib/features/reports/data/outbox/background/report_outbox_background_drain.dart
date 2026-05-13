import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:chisto_mobile/features/reports/data/api_reports_repository.dart';
import 'package:chisto_mobile/features/reports/data/outbox/background/background_submit_scheduler.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_coordinator.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_migration_from_sp.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart'
    show ReportOutboxRepository, SqfliteReportOutboxRepository;
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';

/// Headless outbox drain invoked from Workmanager (Android) or BG tasks (iOS).
///
/// Opens its own SQLite + HTTP stack (no [ServiceLocator]) so the callback
/// isolate stays independent of the UI isolate.
abstract final class ReportOutboxBackgroundDrain {
  /// Value passed to [Workmanager().registerOneOffTask] as `taskName` (Android).
  static const String taskName = 'reportOutboxDrain';

  /// Stable [uniqueName] for one-off registration (also used as iOS task id).
  static const String uniqueTaskName = 'chisto.reportOutbox.drain';

  static Future<bool> run() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final AppConfig config = AppConfig.fromEnvironment();
      final SecureTokenStorage tokenStorage = SecureTokenStorage();
      final String? token = await tokenStorage.accessToken;
      if (token == null || token.isEmpty) {
        return true;
      }
      final ApiClient client = ApiClient(
        config: config,
        accessToken: () => token,
        onUnauthorized: () {},
      );
      final ReportsApiRepository api = ApiReportsRepository(client: client);
      final ReportOutboxRepository repo = await SqfliteReportOutboxRepository.open();
      await ReportOutboxMigrationFromSp.runOnce(repo);
      final ReportOutboxCoordinator coordinator = ReportOutboxCoordinator(
        repository: repo,
        reportsApi: api,
        backgroundSubmitScheduler: InProcessBackgroundSubmitScheduler(),
      );
      await coordinator.scheduleProcess();
      await coordinator.dispose();
      client.dispose();
      return true;
    } on Exception catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ReportOutboxBackgroundDrain] failed: $e\n$st');
      }
      return false;
    }
  }
}
