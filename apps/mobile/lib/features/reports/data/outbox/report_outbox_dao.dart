import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_database.dart';
import 'package:sqflite/sqflite.dart';

/// Sqflite-only access for the report outbox table (no domain mapping).
class ReportOutboxDao {
  ReportOutboxDao(this._db);

  final Database _db;

  Future<void> insertRow(Map<String, Object?> row) async {
    await _db.insert(
      ReportOutboxDatabase.tableOutbox,
      row,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateRow(Map<String, Object?> row, String id) async {
    await _db.update(
      ReportOutboxDatabase.tableOutbox,
      row,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<List<Map<String, Object?>>> queryById(String id) async {
    return _db.query(
      ReportOutboxDatabase.tableOutbox,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
  }

  Future<List<Map<String, Object?>>> queryByIdTxn(Transaction txn, String id) async {
    return txn.query(
      ReportOutboxDatabase.tableOutbox,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
  }

  Future<List<Map<String, Object?>>> rawQueryNextProcessable(int nowMs) async {
    return _db.rawQuery(
      '''
SELECT * FROM ${ReportOutboxDatabase.tableOutbox}
WHERE state IN ('pending', 'uploading', 'submitting', 'cooldown')
  AND (cooldown_until_ms IS NULL OR cooldown_until_ms <= ?)
  AND (
    state IN ('uploading', 'submitting', 'cooldown')
    OR (state = 'pending' AND submit_requested = 1)
  )
ORDER BY created_at_ms ASC
LIMIT 1
''',
      <Object>[nowMs],
    );
  }

  Future<int> rawCountSubmitPipeline() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      '''
SELECT COUNT(*) AS c FROM ${ReportOutboxDatabase.tableOutbox}
WHERE state IN ('uploading', 'submitting', 'cooldown')
   OR (state = 'pending' AND submit_requested = 1)
''',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> rawCountAllRows() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${ReportOutboxDatabase.tableOutbox}',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> deleteWhereId(String id) async {
    await _db.delete(
      ReportOutboxDatabase.tableOutbox,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> runTransaction(
    Future<void> Function(Transaction txn) action,
  ) {
    return _db.transaction(action);
  }
}
