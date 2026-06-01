import 'package:chisto_infrastructure/core/auth/background_session_refresh.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:chisto_networking/chisto_networking.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_reports/src/data/api_reports_repository.dart';
import 'package:feature_reports/src/data/outbox/background/background_submit_scheduler.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_coordinator.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_migration_from_sp.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_repository.dart'
    show ReportOutboxRepository, SqfliteReportOutboxRepository;
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Headless outbox drain invoked from Workmanager (Android) or BG tasks (iOS).
///
/// Opens its own SQLite + HTTP stack (no [AppBootstrap]) so the callback
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
      final String? token = await BackgroundSessionRefresh.resolveAccessToken(
        config: config,
        tokenStorage: tokenStorage,
      );
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          AppLog.verbose(
            '[ReportOutboxBackgroundDrain] no session; skip drain',
          );
        }
        return true;
      }

      String? cachedToken = token;
      final ApiClient client = createBackgroundApiClient(
        config: config,
        accessToken: () => cachedToken,
        refreshSession: () async {
          final RefreshOutcome outcome =
              await BackgroundSessionRefresh.tryRefresh(
                config: config,
                tokenStorage: tokenStorage,
              );
          if (outcome == RefreshOutcome.success) {
            cachedToken = await tokenStorage.accessToken;
          }
          return outcome;
        },
      );
      final ReportsApiRepository api = ApiReportsRepository(client: client);
      final ReportOutboxRepository repo =
          await SqfliteReportOutboxRepository.open();
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
        AppLog.verbose('[ReportOutboxBackgroundDrain] failed: $e\n$st');
      }
      return false;
    }
  }
}
