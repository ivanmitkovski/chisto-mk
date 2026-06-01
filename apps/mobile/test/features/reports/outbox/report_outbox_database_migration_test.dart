import 'dart:io';

import 'package:feature_reports/src/data/outbox/report_outbox_constants.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('submit_requested migration defaults wizard autosave rows to 0', () async {
    final String path =
        '${Directory.systemTemp.path}/outbox_mig_${DateTime.now().microsecondsSinceEpoch}.db';
    const String table = ReportOutboxDatabase.tableOutbox;

    final Database legacy = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
CREATE TABLE $table (
  id TEXT NOT NULL PRIMARY KEY,
  idempotency_key TEXT NOT NULL UNIQUE,
  draft_json TEXT NOT NULL,
  state TEXT NOT NULL,
  media_urls_json TEXT,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error_code TEXT,
  last_error_message TEXT,
  cooldown_until_ms INTEGER,
  report_id TEXT,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL
)''');
      },
    );
    await legacy.insert(table, <String, Object?>{
      'id': kReportWizardDraftRowId,
      'idempotency_key': wizardDraftPlaceholderIdempotencyKey(),
      'draft_json': '{"draft":{},"title":"","description":""}',
      'state': 'pending',
      'attempt_count': 0,
      'created_at_ms': 1,
      'updated_at_ms': 1,
    });
    await legacy.close();

    final Database upgraded = await openDatabase(
      path,
      version: 4,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $table ADD COLUMN submit_requested INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            '''
UPDATE $table SET submit_requested = 0
WHERE id = ? AND state = 'pending'
''',
            <Object>[kReportWizardDraftRowId],
          );
        }
      },
    );
    try {
      final List<Map<String, Object?>> rows = await upgraded.query(
        table,
        where: 'id = ?',
        whereArgs: <Object>[kReportWizardDraftRowId],
      );
      expect(rows, hasLength(1));
      expect(rows.first['submit_requested'], 0);
    } finally {
      await upgraded.close();
      await File(path).delete();
    }
  });
}
