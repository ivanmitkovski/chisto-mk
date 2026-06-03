import 'dart:async';
import 'dart:io';

import 'package:feature_reports/src/data/outbox/report_outbox_constants.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_coordinator.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_entry.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_repository.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/widget_test_bootstrap.dart';

Future<Database> _openLeaseTestDb(String fileName) async {
  final Directory root = await Directory.systemTemp.createTemp('outbox_lease_');
  final String path = p.join(root.path, fileName);
  return openDatabase(
    path,
    version: 5,
    onCreate: (Database db, int v) async {
      await db.execute('''
CREATE TABLE ${ReportOutboxDatabase.tableOutbox} (
  id TEXT NOT NULL PRIMARY KEY,
  idempotency_key TEXT NOT NULL UNIQUE,
  draft_json TEXT NOT NULL,
  state TEXT NOT NULL,
  submit_requested INTEGER NOT NULL DEFAULT 0,
  media_urls_json TEXT,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error_code TEXT,
  last_error_message TEXT,
  cooldown_until_ms INTEGER,
  report_id TEXT,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  current_stage TEXT,
  attempted_stages_json TEXT,
  last_persisted_at_ms INTEGER,
  processing_owner TEXT,
  processing_lease_until_ms INTEGER
)''');
    },
  );
}

ReportDraft _leaseDraft() => ReportDraft(
  category: ReportCategory.other,
  title: 'Title',
  description: 'Desc',
  latitude: 41.99,
  longitude: 21.43,
  address: 'Skopje',
);

class _LeaseStubApi implements ReportsApiRepository {
  _LeaseStubApi({required this.onSubmit});

  final Future<ReportSubmitResult> Function({
    required double latitude,
    required double longitude,
    required String title,
    String? description,
    List<String>? mediaUrls,
    String? category,
    int? severity,
    String? address,
    String? cleanupEffort,
    String? idempotencyKey,
  })
  onSubmit;

  final List<String?> recordedIdempotencyKeys = <String?>[];

  @override
  Future<ReportSubmitResult> submitReport({
    required double latitude,
    required double longitude,
    required String title,
    String? description,
    List<String>? mediaUrls,
    String? category,
    int? severity,
    String? address,
    String? cleanupEffort,
    String? idempotencyKey,
  }) async {
    recordedIdempotencyKeys.add(idempotencyKey);
    return onSubmit(
      latitude: latitude,
      longitude: longitude,
      title: title,
      description: description,
      mediaUrls: mediaUrls,
      category: category,
      severity: severity,
      address: address,
      cleanupEffort: cleanupEffort,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('two coordinators cannot both claim the same row', () async {
    final Database db = await _openLeaseTestDb(
      'lease_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    addTearDown(db.close);
    final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);

    final Completer<void> releaseSubmit = Completer<void>();
    final _LeaseStubApi api = _LeaseStubApi(
      onSubmit:
          ({
            required double latitude,
            required double longitude,
            required String title,
            String? description,
            List<String>? mediaUrls,
            String? category,
            int? severity,
            String? address,
            String? cleanupEffort,
            String? idempotencyKey,
          }) async {
            await releaseSubmit.future;
            return const ReportSubmitResult(
              reportId: 'r1',
              reportNumber: 'R-1',
              siteId: 's1',
              isNewSite: false,
              pointsAwarded: 0,
            );
          },
    );

    final int t = DateTime.now().millisecondsSinceEpoch;
    await repo.insert(
      ReportOutboxEntry(
        id: kReportWizardDraftRowId,
        idempotencyKey: 'lease-test-key-12',
        draft: _leaseDraft(),
        title: 'Title',
        description: 'Desc',
        submitRequested: true,
        state: ReportOutboxState.submitting,
        attemptCount: 0,
        createdAtMs: t,
        updatedAtMs: t,
      ),
    );

    final ReportOutboxCoordinator a = ReportOutboxCoordinator(
      repository: repo,
      reportsApi: api,
    );
    final ReportOutboxCoordinator b = ReportOutboxCoordinator(
      repository: repo,
      reportsApi: api,
    );

    final Future<void> drainA = a.scheduleProcess();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final Future<void> drainB = b.scheduleProcess();
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(api.recordedIdempotencyKeys.length, 1);

    releaseSubmit.complete();
    await drainA;
    await drainB;
    await a.dispose();
    await b.dispose();
  });
}
