import 'package:feature_reports/src/data/outbox/report_outbox_database.dart';
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

  Future<List<Map<String, Object?>>> queryByIdTxn(
    Transaction txn,
    String id,
  ) async {
    return txn.query(
      ReportOutboxDatabase.tableOutbox,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
  }

  static const String _processableWhere = '''
state IN ('pending', 'uploading', 'submitting', 'cooldown')
  AND (cooldown_until_ms IS NULL OR cooldown_until_ms <= ?)
  AND (
    state IN ('uploading', 'submitting', 'cooldown')
    OR (state = 'pending' AND submit_requested = 1)
  )
  AND (processing_lease_until_ms IS NULL OR processing_lease_until_ms <= ?)
''';

  Future<List<Map<String, Object?>>> rawQueryNextProcessable(int nowMs) async {
    return _db.rawQuery(
      '''
SELECT * FROM ${ReportOutboxDatabase.tableOutbox}
WHERE $_processableWhere
ORDER BY created_at_ms ASC
LIMIT 1
''',
      <Object>[nowMs, nowMs],
    );
  }

  /// Atomically claims the next processable row for [ownerId] until [leaseUntilMs].
  Future<Map<String, Object?>?> rawClaimNextProcessable({
    required int nowMs,
    required String ownerId,
    required int leaseUntilMs,
  }) async {
    Map<String, Object?>? claimed;
    await _db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.rawQuery(
        '''
SELECT * FROM ${ReportOutboxDatabase.tableOutbox}
WHERE $_processableWhere
ORDER BY created_at_ms ASC
LIMIT 1
''',
        <Object>[nowMs, nowMs],
      );
      if (rows.isEmpty) {
        return;
      }
      final String id = rows.first['id']! as String;
      final int updated = await txn.rawUpdate(
        '''
UPDATE ${ReportOutboxDatabase.tableOutbox}
SET processing_owner = ?, processing_lease_until_ms = ?, updated_at_ms = ?
WHERE id = ?
  AND (processing_lease_until_ms IS NULL OR processing_lease_until_ms <= ?)
''',
        <Object>[ownerId, leaseUntilMs, nowMs, id, nowMs],
      );
      if (updated == 0) {
        return;
      }
      claimed = Map<String, Object?>.from(rows.first)
        ..['processing_owner'] = ownerId
        ..['processing_lease_until_ms'] = leaseUntilMs
        ..['updated_at_ms'] = nowMs;
    });
    return claimed;
  }

  Future<void> rawReleaseLease(String id) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    await _db.update(
      ReportOutboxDatabase.tableOutbox,
      <String, Object?>{
        'processing_owner': null,
        'processing_lease_until_ms': null,
        'updated_at_ms': now,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<int> rawCountSubmitPipeline() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery('''
SELECT COUNT(*) AS c FROM ${ReportOutboxDatabase.tableOutbox}
WHERE state IN ('uploading', 'submitting', 'cooldown')
   OR (state = 'pending' AND submit_requested = 1)
''');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> rawCountSubmitPipelineTxn(Transaction txn) async {
    final List<Map<String, Object?>> rows = await txn.rawQuery('''
SELECT COUNT(*) AS c FROM ${ReportOutboxDatabase.tableOutbox}
WHERE state IN ('uploading', 'submitting', 'cooldown')
   OR (state = 'pending' AND submit_requested = 1)
''');
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

  Future<void> deleteAllRows() async {
    await _db.delete(ReportOutboxDatabase.tableOutbox);
  }

  Future<void> runTransaction(Future<void> Function(Transaction txn) action) {
    return _db.transaction(action);
  }
}
