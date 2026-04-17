import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Persisted queue for chat sends that failed or were deferred offline (text only for now).
///
/// Same [clientMessageId] is kept across retries and app restarts for idempotent POSTs.
///
/// PRIVACY: Stores user-authored message bodies in SQLite. Must be cleared on logout.
class ChatOutboxEntry {
  const ChatOutboxEntry({
    required this.eventId,
    required this.clientMessageId,
    required this.tempId,
    required this.body,
    this.replyToId,
    required this.createdAtMs,
  });

  final String eventId;
  final String clientMessageId;
  final String tempId;
  final String body;
  final String? replyToId;
  final int createdAtMs;
}

/// SQLite-backed store; uses [databaseFactory] from `sqflite` (native mobile) or
/// `sqflite_common_ffi` after [main] sets it on desktop.
class ChatOutboxStore {
  ChatOutboxStore._();
  static final ChatOutboxStore shared = ChatOutboxStore._();

  static const int _maxRowsPerEvent = 20;
  static const String _table = 'chat_outbox';

  Database? _db;

  Future<Database> _database() async {
    if (_db != null) {
      return _db!;
    }
    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String path = '$dir/chat_outbox.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
CREATE TABLE $_table (
  event_id TEXT NOT NULL,
  client_message_id TEXT NOT NULL,
  temp_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  body TEXT NOT NULL,
  reply_to_id TEXT,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (event_id, client_message_id)
)''');
      },
    );
    return _db!;
  }

  Future<int> _countForEvent(String eventId) async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE event_id = ?',
      <Object>[eventId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Returns false if the per-event cap is reached.
  Future<bool> enqueueText({
    required String eventId,
    required String tempId,
    required String clientMessageId,
    required String body,
    String? replyToId,
  }) async {
    if (await _countForEvent(eventId) >= _maxRowsPerEvent) {
      return false;
    }
    final Database db = await _database();
    await db.insert(
      _table,
      <String, Object?>{
        'event_id': eventId,
        'client_message_id': clientMessageId,
        'temp_id': tempId,
        'kind': 'text',
        'body': body,
        'reply_to_id': replyToId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }

  Future<List<ChatOutboxEntry>> listPending(String eventId) async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      where: 'event_id = ?',
      whereArgs: <Object>[eventId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_rowToEntry).toList();
  }

  Future<ChatOutboxEntry?> peekNext(String eventId) async {
    final List<ChatOutboxEntry> all = await listPending(eventId);
    return all.isEmpty ? null : all.first;
  }

  Future<void> remove(String eventId, String clientMessageId) async {
    final Database db = await _database();
    await db.delete(
      _table,
      where: 'event_id = ? AND client_message_id = ?',
      whereArgs: <Object>[eventId, clientMessageId],
    );
  }

  /// Clears all queued messages and closes the DB handle. Call on logout (see [ApiAuthRepository]).
  Future<void> clearAll() async {
    try {
      final Database db = await _database();
      await db.delete(_table);
    } on Object {
      // Best-effort: storage unavailable, or table missing on a corrupted file.
    }
    if (_db != null) {
      try {
        await _db!.close();
      } on Object {
        // ignore
      }
      _db = null;
    }
  }

  ChatOutboxEntry _rowToEntry(Map<String, Object?> row) {
    return ChatOutboxEntry(
      eventId: row['event_id']! as String,
      clientMessageId: row['client_message_id']! as String,
      tempId: row['temp_id']! as String,
      body: row['body']! as String,
      replyToId: row['reply_to_id'] as String?,
      createdAtMs: row['created_at']! as int,
    );
  }
}
