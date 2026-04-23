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
    this.syncStatus = ChatOutboxStore.syncStatusPending,
    this.attemptCount = 0,
    this.lastErrorCode,
  });

  final String eventId;
  final String clientMessageId;
  final String tempId;
  final String body;
  final String? replyToId;
  final int createdAtMs;

  /// `pending` (retry) or `failed` (terminal; needs user action in chat).
  final String syncStatus;
  final int attemptCount;
  final String? lastErrorCode;

  bool get isPending => syncStatus == ChatOutboxStore.syncStatusPending;
  bool get isFailed => syncStatus == ChatOutboxStore.syncStatusFailed;
}

/// SQLite-backed store; uses [databaseFactory] from `sqflite` (native mobile) or
/// `sqflite_common_ffi` after [main] sets it on desktop.
class ChatOutboxStore {
  ChatOutboxStore._();
  static final ChatOutboxStore shared = ChatOutboxStore._();

  static const int _maxRowsPerEvent = 20;

  /// Server-aligned cap for text rows waiting offline per event (see conventions §10).
  static int get maxPendingTextRowsPerEvent => _maxRowsPerEvent;

  static const String syncStatusPending = 'pending';
  static const String syncStatusFailed = 'failed';

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
      version: 2,
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
  sync_status TEXT NOT NULL DEFAULT 'pending',
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error_code TEXT,
  PRIMARY KEY (event_id, client_message_id)
)''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
          );
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN attempt_count INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN last_error_code TEXT',
          );
        }
      },
    );
    return _db!;
  }

  /// True when the per-event cap is reached and [enqueueText] would return false.
  Future<bool> isOutboxFullForEvent(String eventId) async {
    return (await _countForEvent(eventId)) >= _maxRowsPerEvent;
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
        'sync_status': syncStatusPending,
        'attempt_count': 0,
        'last_error_code': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }

  /// Rows eligible for automatic send (excludes terminal [syncStatusFailed]).
  Future<List<ChatOutboxEntry>> listPending(String eventId) async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      where: 'event_id = ? AND sync_status = ?',
      whereArgs: <Object>[eventId, syncStatusPending],
      orderBy: 'created_at ASC',
    );
    return rows.map(_rowToEntry).toList();
  }

  /// Pending and failed rows for restoring bubbles after restart.
  Future<List<ChatOutboxEntry>> listPendingAndFailed(String eventId) async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      where: 'event_id = ? AND sync_status IN (?, ?)',
      whereArgs: <Object>[eventId, syncStatusPending, syncStatusFailed],
      orderBy: 'created_at ASC',
    );
    return rows.map(_rowToEntry).toList();
  }

  Future<ChatOutboxEntry?> peekNext(String eventId) async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      where: 'event_id = ? AND sync_status = ?',
      whereArgs: <Object>[eventId, syncStatusPending],
      orderBy: 'created_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _rowToEntry(rows.first);
  }

  /// Oldest pending row across all events (for app-wide drain).
  Future<ChatOutboxEntry?> peekNextGlobally() async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      where: 'sync_status = ?',
      whereArgs: <Object>[syncStatusPending],
      orderBy: 'created_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _rowToEntry(rows.first);
  }

  Future<int> totalPendingCount() async {
    try {
      final Database db = await _database();
      final List<Map<String, Object?>> rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $_table WHERE sync_status = ?',
        <Object>[syncStatusPending],
      );
      return Sqflite.firstIntValue(rows) ?? 0;
    } on DatabaseException catch (e) {
      if (e.isDatabaseClosedError()) {
        return 0;
      }
      rethrow;
    }
  }

  Future<int> totalFailedCount() async {
    try {
      final Database db = await _database();
      final List<Map<String, Object?>> rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $_table WHERE sync_status = ?',
        <Object>[syncStatusFailed],
      );
      return Sqflite.firstIntValue(rows) ?? 0;
    } on DatabaseException catch (e) {
      if (e.isDatabaseClosedError()) {
        return 0;
      }
      rethrow;
    }
  }

  /// Distinct [eventId] values that still have pending or failed outbox rows.
  Future<List<String>> listDistinctEventIdsWithWork() async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT DISTINCT event_id FROM $_table WHERE sync_status IN (?, ?) ORDER BY event_id ASC',
      <Object>[syncStatusPending, syncStatusFailed],
    );
    return rows
        .map((Map<String, Object?> r) => r['event_id'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }

  Future<void> remove(String eventId, String clientMessageId) async {
    final Database db = await _database();
    await db.delete(
      _table,
      where: 'event_id = ? AND client_message_id = ?',
      whereArgs: <Object>[eventId, clientMessageId],
    );
  }

  Future<void> recordRetryableFailure(
    String eventId,
    String clientMessageId, {
    String? lastErrorCode,
  }) async {
    final Database db = await _database();
    await db.rawUpdate(
      '''
UPDATE $_table
SET attempt_count = attempt_count + 1,
    last_error_code = COALESCE(?, last_error_code),
    sync_status = ?
WHERE event_id = ? AND client_message_id = ?
''',
      <Object?>[lastErrorCode, syncStatusPending, eventId, clientMessageId],
    );
  }

  /// Re-queue every terminal failed row so the coordinator can retry send (user-initiated).
  Future<int> requeueAllFailedRows() async {
    final Database db = await _database();
    return db.rawUpdate(
      '''
UPDATE $_table
SET sync_status = ?,
    attempt_count = 0,
    last_error_code = NULL
WHERE sync_status = ?
''',
      <Object>[syncStatusPending, syncStatusFailed],
    );
  }

  Future<void> markTerminalFailure(
    String eventId,
    String clientMessageId,
    String errorCode,
  ) async {
    final Database db = await _database();
    await db.update(
      _table,
      <String, Object?>{
        'sync_status': syncStatusFailed,
        'last_error_code': errorCode,
      },
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
    final String status =
        (row['sync_status'] as String?)?.trim().isNotEmpty == true
            ? row['sync_status']! as String
            : syncStatusPending;
    return ChatOutboxEntry(
      eventId: row['event_id']! as String,
      clientMessageId: row['client_message_id']! as String,
      tempId: row['temp_id']! as String,
      body: row['body']! as String,
      replyToId: row['reply_to_id'] as String?,
      createdAtMs: row['created_at']! as int,
      syncStatus: status,
      attemptCount: (row['attempt_count'] as num?)?.toInt() ?? 0,
      lastErrorCode: row['last_error_code'] as String?,
    );
  }
}
