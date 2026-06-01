import 'package:sqflite/sqflite.dart';

/// Returns true when [e] indicates the cached sqflite handle was closed (hot restart).
bool isDatabaseClosedError(Object e) {
  return e is DatabaseException && e.toString().contains('database_closed');
}

/// Runs [action] with [db], reopening once after [database_closed].
Future<T> withSqfliteDb<T>({
  required Future<Database> Function() open,
  required Database? Function() getCached,
  required void Function(Database?) setCached,
  required Future<T> Function(Database db) action,
}) async {
  try {
    return await action(await _ensureOpen(open, getCached, setCached));
  } on DatabaseException catch (e) {
    if (!isDatabaseClosedError(e)) {
      rethrow;
    }
    setCached(null);
    return action(await _ensureOpen(open, getCached, setCached));
  }
}

Future<Database> _ensureOpen(
  Future<Database> Function() open,
  Database? Function() getCached,
  void Function(Database?) setCached,
) async {
  final Database? cached = getCached();
  if (cached != null && cached.isOpen) {
    return cached;
  }
  setCached(null);
  final Database db = await open();
  setCached(db);
  return db;
}
