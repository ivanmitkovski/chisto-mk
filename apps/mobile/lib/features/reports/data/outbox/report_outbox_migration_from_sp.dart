import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:chisto_mobile/features/reports/data/report_draft_local_store.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-shot migration from legacy SharedPreferences draft into SQLite outbox.
class ReportOutboxMigrationFromSp {
  ReportOutboxMigrationFromSp._();

  static const String _prefsKey = 'reports_outbox_sp_migration_v1_done';

  /// If SP has a non-trivial draft and migration has not run, imports then clears SP.
  static Future<void> runOnce(
    ReportOutboxRepository repo, {
    SharedPreferences? prefsOverride,
  }) async {
    final SharedPreferences prefs =
        prefsOverride ?? await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKey) == true) {
      return;
    }
    final ReportDraft? saved = await ReportDraftLocalStore.loadDraft();
    if (saved == null) {
      await prefs.setBool(_prefsKey, true);
      return;
    }
    if (!saved.hasPersistableWizardBody) {
      await ReportDraftLocalStore.clear();
      await prefs.setBool(_prefsKey, true);
      return;
    }

    final ReportOutboxEntry? existing = await repo.getById(kReportWizardDraftRowId);
    if (existing != null && isReportWizardDraftEntryResumable(existing)) {
      await ReportDraftLocalStore.clear();
      await prefs.setBool(_prefsKey, true);
      return;
    }

    await repo.saveWizardDraft(
      draft: saved,
      title: saved.title,
      description: saved.description,
    );
    await ReportDraftLocalStore.clear();
    chistoReportsBreadcrumb(
      'report_draft',
      'migration_sp_imported',
      data: <String, Object?>{'hasPhotos': saved.hasPhotos},
    );
    await prefs.setBool(_prefsKey, true);
  }
}
