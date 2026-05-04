import 'dart:io';

import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_database.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../shared/widget_test_bootstrap.dart';

Future<Database> _openTestDb(String fileName) async {
  final Directory root = await Directory.systemTemp.createTemp('outbox_repo_');
  final String path = p.join(root.path, fileName);
  return openDatabase(
    path,
    version: 3,
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
  last_persisted_at_ms INTEGER
)''');
      await db.execute(
        'CREATE INDEX idx_report_outbox_state ON ${ReportOutboxDatabase.tableOutbox} (state, updated_at_ms)',
      );
    },
    onUpgrade: (Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          'ALTER TABLE ${ReportOutboxDatabase.tableOutbox} ADD COLUMN submit_requested INTEGER NOT NULL DEFAULT 1',
        );
      }
      if (oldVersion < 3) {
        await db.execute(
          'ALTER TABLE ${ReportOutboxDatabase.tableOutbox} ADD COLUMN current_stage TEXT',
        );
        await db.execute(
          'ALTER TABLE ${ReportOutboxDatabase.tableOutbox} ADD COLUMN attempted_stages_json TEXT',
        );
        await db.execute(
          'ALTER TABLE ${ReportOutboxDatabase.tableOutbox} ADD COLUMN last_persisted_at_ms INTEGER',
        );
      }
    },
  );
}

ReportOutboxEntry _entry({
  required String id,
  required String idem,
  required ReportOutboxState state,
  required int createdAtMs,
  bool submitRequested = false,
  int? cooldownUntilMs,
}) {
  return ReportOutboxEntry(
    id: id,
    idempotencyKey: idem,
    draft: ReportDraft(
      title: 't',
      category: ReportCategory.other,
      latitude: 41.99,
      longitude: 21.43,
    ),
    title: 't',
    description: '',
    submitRequested: submitRequested,
    state: state,
    attemptCount: 0,
    createdAtMs: createdAtMs,
    updatedAtMs: createdAtMs,
    cooldownUntilMs: cooldownUntilMs,
  );
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  group('SqfliteReportOutboxRepository', () {
    test('roundtrip insert and getById', () async {
      final Database db = await _openTestDb('r1.db');
      final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);
      final ReportOutboxEntry e = _entry(
        id: 'a1',
        idem: 'idem_a1',
        state: ReportOutboxState.pending,
        createdAtMs: 100,
        submitRequested: true,
      );
      await repo.insert(e);
      final ReportOutboxEntry? got = await repo.getById('a1');
      expect(got?.id, 'a1');
      expect(got?.idempotencyKey, 'idem_a1');
      expect(got?.state, ReportOutboxState.pending);
      await db.close();
    });

    test('update transitions persist', () async {
      final Database db = await _openTestDb('r2.db');
      final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);
      final ReportOutboxEntry e = _entry(
        id: 'a2',
        idem: 'idem_a2',
        state: ReportOutboxState.pending,
        createdAtMs: 200,
      );
      await repo.insert(e);
      await repo.update(
        e.copyWith(
          state: ReportOutboxState.submitting,
          attemptCount: 2,
          updatedAtMs: 999,
        ),
      );
      final ReportOutboxEntry? got = await repo.getById('a2');
      expect(got?.state, ReportOutboxState.submitting);
      expect(got?.attemptCount, 2);
      await db.close();
    });

    test('getWizardDraftEntry equals getById(kReportWizardDraftRowId)', () async {
      final Database db = await _openTestDb('r3.db');
      final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);
      final ReportOutboxEntry e = _entry(
        id: kReportWizardDraftRowId,
        idem: 'idem_w',
        state: ReportOutboxState.pending,
        createdAtMs: 300,
      );
      await repo.insert(e);
      final ReportOutboxEntry? a = await repo.getWizardDraftEntry();
      final ReportOutboxEntry? b = await repo.getById(kReportWizardDraftRowId);
      expect(a?.id, b?.id);
      await db.close();
    });

    test('saveWizardDraft insert clears media and errors on new row', () async {
      final Database db = await _openTestDb('r4.db');
      final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);
      await repo.saveWizardDraft(
        draft: ReportDraft(title: 'x', category: ReportCategory.other),
        title: 'x',
        description: 'd',
      );
      final ReportOutboxEntry? row = await repo.getById(kReportWizardDraftRowId);
      expect(row, isNotNull);
      expect(row!.submitRequested, false);
      expect(row.state, ReportOutboxState.pending);
      await db.close();
    });

    test('saveWizardDraft upsert clears media errors cooldown', () async {
      final Database db = await _openTestDb('r5.db');
      final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);
      final int t = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(
        _entry(
          id: kReportWizardDraftRowId,
          idem: 'old',
          state: ReportOutboxState.failed,
          createdAtMs: t,
        ).copyWith(
          lastErrorCode: 'E',
          cooldownUntilMs: t + 99999,
        ),
      );
      await repo.saveWizardDraft(
        draft: ReportDraft(title: 'y', category: ReportCategory.other),
        title: 'y',
        description: '',
      );
      final ReportOutboxEntry? row = await repo.getById(kReportWizardDraftRowId);
      expect(row?.lastErrorCode, isNull);
      expect(row?.cooldownUntilMs, isNull);
      expect(row?.mediaUrls, isNull);
      await db.close();
    });

    test('countSubmitPipeline and countAllRows matrix', () async {
      final Database db = await _openTestDb('r6.db');
      final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);
      await repo.insert(
        _entry(
          id: 'p1',
          idem: 'i1',
          state: ReportOutboxState.pending,
          createdAtMs: 1,
          submitRequested: false,
        ),
      );
      await repo.insert(
        _entry(
          id: 'p2',
          idem: 'i2',
          state: ReportOutboxState.pending,
          createdAtMs: 2,
          submitRequested: true,
        ),
      );
      await repo.insert(
        _entry(
          id: 'u1',
          idem: 'i3',
          state: ReportOutboxState.uploading,
          createdAtMs: 3,
        ),
      );
      expect(await repo.countAllRows(), 3);
      expect(await repo.countSubmitPipeline(), 2);
      await db.close();
    });

    test('getNextProcessable excludes pending when submit_requested is 0', () async {
      final Database db = await _openTestDb('r7.db');
      final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);
      await repo.insert(
        _entry(
          id: 'only',
          idem: 'i',
          state: ReportOutboxState.pending,
          createdAtMs: 10,
          submitRequested: false,
        ),
      );
      expect(await repo.getNextProcessable(), isNull);
      await db.close();
    });

    test('getNextProcessable respects cooldown_until_ms ordering', () async {
      final Database db = await _openTestDb('r8.db');
      final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);
      final int now = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(
        _entry(
          id: 'late',
          idem: 'l1',
          state: ReportOutboxState.pending,
          createdAtMs: 100,
          submitRequested: true,
        ).copyWith(cooldownUntilMs: now + 60000),
      );
      await repo.insert(
        _entry(
          id: 'soon',
          idem: 'l2',
          state: ReportOutboxState.pending,
          createdAtMs: 200,
          submitRequested: true,
        ).copyWith(cooldownUntilMs: now - 1),
      );
      final ReportOutboxEntry? next = await repo.getNextProcessable();
      expect(next?.id, 'soon');
      await db.close();
    });

    test('getNextProcessable orders by created_at_ms', () async {
      final Database db = await _openTestDb('r9.db');
      final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);
      await repo.insert(
        _entry(
          id: 'second',
          idem: 'o2',
          state: ReportOutboxState.pending,
          createdAtMs: 200,
          submitRequested: true,
        ),
      );
      await repo.insert(
        _entry(
          id: 'first',
          idem: 'o1',
          state: ReportOutboxState.pending,
          createdAtMs: 100,
          submitRequested: true,
        ),
      );
      final ReportOutboxEntry? next = await repo.getNextProcessable();
      expect(next?.id, 'first');
      await db.close();
    });

    test('delete removes row', () async {
      final Database db = await _openTestDb('r10.db');
      final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(db);
      await repo.insert(
        _entry(
          id: 'del',
          idem: 'd1',
          state: ReportOutboxState.succeeded,
          createdAtMs: 1,
        ),
      );
      await repo.delete('del');
      expect(await repo.getById('del'), isNull);
      await db.close();
    });
  });
}
