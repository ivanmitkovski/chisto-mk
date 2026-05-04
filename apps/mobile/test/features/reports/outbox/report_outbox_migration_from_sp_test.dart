import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_migration_from_sp.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:chisto_mobile/features/reports/data/report_draft_local_store.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOutbox implements ReportOutboxRepository {
  ReportOutboxEntry? wizard;
  int saveWizardCalls = 0;

  @override
  Future<int> countAllRows() async => wizard == null ? 0 : 1;

  @override
  Future<int> countSubmitPipeline() async => 0;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<ReportOutboxEntry?> getById(String id) async =>
      id == kReportWizardDraftRowId ? wizard : null;

  @override
  Future<ReportOutboxEntry?> getNextProcessable() async => null;

  @override
  Future<ReportOutboxEntry?> getWizardDraftEntry() async => wizard;

  @override
  Future<void> insert(ReportOutboxEntry entry) async {}

  @override
  Future<void> saveWizardDraft({
    required ReportDraft draft,
    required String title,
    required String description,
    String? currentStageName,
    List<String>? attemptedStageNames,
    int? lastPersistedAtMs,
  }) async {
    saveWizardCalls++;
    final int t = DateTime.now().millisecondsSinceEpoch;
    wizard = ReportOutboxEntry(
      id: kReportWizardDraftRowId,
      idempotencyKey: 'idem_$kReportWizardDraftRowId',
      draft: draft,
      title: title,
      description: description,
      submitRequested: false,
      state: ReportOutboxState.pending,
      attemptCount: 0,
      createdAtMs: wizard?.createdAtMs ?? t,
      updatedAtMs: t,
      currentStageName: currentStageName,
      attemptedStageNames: attemptedStageNames ?? const <String>[],
      lastPersistedAtMs: lastPersistedAtMs,
    );
  }

  @override
  Future<void> update(ReportOutboxEntry entry) async {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReportDraftLocalStore.clear();
  });

  test('imports SP draft when wizard row is trivial', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeOutbox repo = _FakeOutbox();
    await ReportDraftLocalStore.saveDraft(
      draft: ReportDraft(title: 'From SP'),
      title: 'From SP',
      description: '',
    );

    await ReportOutboxMigrationFromSp.runOnce(repo, prefsOverride: prefs);

    expect(repo.saveWizardCalls, 1);
    expect(repo.wizard?.title, 'From SP');
    expect(prefs.getBool('reports_outbox_sp_migration_v1_done'), isTrue);
    expect(await ReportDraftLocalStore.loadDraft(), isNull);
  });

  test('skips import when wizard already has content', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeOutbox repo = _FakeOutbox();
    await repo.saveWizardDraft(
      draft: ReportDraft(title: 'SQLite'),
      title: 'SQLite',
      description: '',
    );
    repo.saveWizardCalls = 0;

    await ReportDraftLocalStore.saveDraft(
      draft: ReportDraft(title: 'From SP'),
      title: 'From SP',
      description: '',
    );

    await ReportOutboxMigrationFromSp.runOnce(repo, prefsOverride: prefs);

    expect(repo.saveWizardCalls, 0);
    expect(repo.wizard?.title, 'SQLite');
    expect(prefs.getBool('reports_outbox_sp_migration_v1_done'), isTrue);
  });

  test('no-op when migration flag already set', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reports_outbox_sp_migration_v1_done', true);
    final _FakeOutbox repo = _FakeOutbox();
    await ReportDraftLocalStore.saveDraft(
      draft: ReportDraft(title: 'From SP'),
      title: 'From SP',
      description: '',
    );

    await ReportOutboxMigrationFromSp.runOnce(repo, prefsOverride: prefs);

    expect(repo.saveWizardCalls, 0);
  });
}
