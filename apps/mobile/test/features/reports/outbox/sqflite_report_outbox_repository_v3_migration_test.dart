import 'dart:convert';
import 'dart:io';

import 'package:chisto_mobile/features/reports/data/outbox/report_draft_json_codec.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_database.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../shared/widget_test_bootstrap.dart';

Future<Database> _openV2(String path) {
  return openDatabase(
    path,
    version: 2,
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
  updated_at_ms INTEGER NOT NULL
)''');
      await db.execute(
        'CREATE INDEX idx_report_outbox_state ON ${ReportOutboxDatabase.tableOutbox} (state, updated_at_ms)',
      );
    },
  );
}

Future<void> _upgradeToV3(Database db, int oldVersion, int newVersion) async {
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
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('v2 database upgrades to v3 and preserves wizard row', () async {
    final Directory root = await Directory.systemTemp.createTemp('outbox_v3_');
    final String path = p.join(root.path, 'outbox.db');

    final Database v2 = await _openV2(path);
    final String draftJson = jsonEncode(
      ReportDraftJsonCodec.encode(
        draft: ReportDraft(title: 'Keep me'),
        title: 'Keep me',
        description: '',
      ),
    );
    await v2.insert(ReportOutboxDatabase.tableOutbox, <String, Object?>{
      'id': kReportWizardDraftRowId,
      'idempotency_key': 'idem_$kReportWizardDraftRowId',
      'draft_json': draftJson,
      'state': 'pending',
      'submit_requested': 0,
      'attempt_count': 0,
      'created_at_ms': 1000,
      'updated_at_ms': 1000,
    });
    await v2.close();

    final Database v3 = await openDatabase(
      path,
      version: 3,
      onUpgrade: _upgradeToV3,
    );

    final List<Map<String, Object?>> cols = await v3.rawQuery(
      'PRAGMA table_info(${ReportOutboxDatabase.tableOutbox})',
    );
    final List<String> names = cols
        .map((Map<String, Object?> r) => r['name']! as String)
        .toList();
    expect(names, contains('current_stage'));
    expect(names, contains('attempted_stages_json'));
    expect(names, contains('last_persisted_at_ms'));

    final SqfliteReportOutboxRepository repo = SqfliteReportOutboxRepository(v3);
    final ReportOutboxEntry? row = await repo.getById(kReportWizardDraftRowId);
    expect(row, isNotNull);
    expect(row!.title, 'Keep me');
    expect(row.draft.title, 'Keep me');

    await v3.close();
    await root.delete(recursive: true);
  });
}
