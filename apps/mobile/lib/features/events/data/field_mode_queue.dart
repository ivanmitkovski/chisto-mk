import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed queue for offline field operations (synced via `POST /events/field-batch`).
class FieldModeQueue {
  FieldModeQueue._();

  static final FieldModeQueue instance = FieldModeQueue._();

  Database? _db;

  Future<Database> _database() async {
    if (_db != null) {
      return _db!;
    }
    final dir = await getApplicationDocumentsDirectory();
    final String path = '${dir.path}/field_mode_queue.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE queue (id INTEGER PRIMARY KEY AUTOINCREMENT, op TEXT NOT NULL, createdAt TEXT NOT NULL)',
        );
      },
    );
    return _db!;
  }

  Future<void> enqueueLiveImpactBags({
    required String eventId,
    required int reportedBagsCollected,
  }) async {
    final Database db = await _database();
    final String op = jsonEncode(<String, dynamic>{
      'type': 'live_impact_bags',
      'eventId': eventId,
      'reportedBagsCollected': reportedBagsCollected,
    });
    await db.insert('queue', <String, Object?>{
      'op': op,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> pendingRows() async {
    final Database db = await _database();
    return db.query('queue', orderBy: 'id ASC');
  }

  Future<void> clearIds(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final Database db = await _database();
    final String placeholders = List<String>.filled(ids.length, '?').join(',');
    await db.rawDelete('DELETE FROM queue WHERE id IN ($placeholders)', ids);
  }

  /// Closes the cached DB handle (e.g. tests switching temp dirs, or process teardown).
  Future<void> closeDatabase() async {
    if (_db != null) {
      try {
        await _db!.close();
      } on Object {
        // ignore
      }
      _db = null;
    }
  }
}
