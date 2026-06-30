import 'package:feature_reports/src/data/outbox/report_outbox_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite schema for the report submit outbox.
class ReportOutboxDatabase {
  ReportOutboxDatabase._();

  static const String _dbName = 'chisto_reports_outbox.db';
  static const int _version = 5;
  static const String tableOutbox = 'report_outbox';

  static Future<Database> open() async {
    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String path = '$dir/$_dbName';
    return openDatabase(
      path,
      version: _version,
      onCreate: (Database db, int v) async {
        await db.execute('''
CREATE TABLE $tableOutbox (
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
        await db.execute(
          'CREATE INDEX idx_report_outbox_state ON $tableOutbox (state, updated_at_ms)',
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $tableOutbox ADD COLUMN submit_requested INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE $tableOutbox ADD COLUMN current_stage TEXT',
          );
          await db.execute(
            'ALTER TABLE $tableOutbox ADD COLUMN attempted_stages_json TEXT',
          );
          await db.execute(
            'ALTER TABLE $tableOutbox ADD COLUMN last_persisted_at_ms INTEGER',
          );
        }
        if (oldVersion < 4) {
          // v2 migration briefly used DEFAULT 1; wizard autosave rows must stay 0.
          await db.execute(
            '''
UPDATE $tableOutbox SET submit_requested = 0
WHERE id = ? AND state = 'pending'
''',
            <Object>[kReportWizardDraftRowId],
          );
        }
        if (oldVersion < 5) {
          await _addColumnIfMissing(
            db,
            column: 'processing_owner',
            definition: 'TEXT',
          );
          await _addColumnIfMissing(
            db,
            column: 'processing_lease_until_ms',
            definition: 'INTEGER',
          );
        }
      },
    );
  }

  /// Safe for devices that partially applied v5 (ALTER ran but version not bumped).
  static Future<void> _addColumnIfMissing(
    Database db, {
    required String column,
    required String definition,
  }) async {
    final List<Map<String, Object?>> info = await db.rawQuery(
      'PRAGMA table_info($tableOutbox)',
    );
    final bool exists = info.any(
      (Map<String, Object?> row) => row['name'] == column,
    );
    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableOutbox ADD COLUMN $column $definition',
      );
    }
  }
}
