import 'package:chisto_persistence/chisto_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _TestDatabaseException extends DatabaseException {
  _TestDatabaseException(String super.message);

  @override
  int? getResultCode() => null;

  @override
  Object? get result => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('isDatabaseClosedError', () {
    test('returns true when exception message contains database_closed', () {
      expect(
        isDatabaseClosedError(_TestDatabaseException('database_closed')),
        isTrue,
      );
    });

    test('returns false for other database errors', () {
      expect(
        isDatabaseClosedError(_TestDatabaseException('no such table: reports')),
        isFalse,
      );
      expect(isDatabaseClosedError(StateError('database_closed')), isFalse);
    });
  });

  group('withSqfliteDb', () {
    test('opens database and caches handle when cache is empty', () async {
      Database? cached;

      final int result = await withSqfliteDb<int>(
        open: () => openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onCreate: (Database db, int version) async {},
        ),
        getCached: () => cached,
        setCached: (Database? db) => cached = db,
        action: (Database db) async {
          expect(db.isOpen, isTrue);
          return 42;
        },
      );

      expect(result, 42);
      expect(cached, isNotNull);
      expect(cached!.isOpen, isTrue);
      await cached!.close();
    });

    test('reuses open cached database without calling open again', () async {
      Database? cached;
      var openCount = 0;

      Future<Database> open() async {
        openCount += 1;
        return openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onCreate: (Database db, int version) async {},
        );
      }

      await withSqfliteDb<void>(
        open: open,
        getCached: () => cached,
        setCached: (Database? db) => cached = db,
        action: (_) async {},
      );
      await withSqfliteDb<void>(
        open: open,
        getCached: () => cached,
        setCached: (Database? db) => cached = db,
        action: (_) async {},
      );

      expect(openCount, 1);
      await cached!.close();
    });

    test('retries once after database_closed and clears cache', () async {
      Database? cached;
      var openCount = 0;
      var actionCount = 0;

      Future<Database> open() async {
        openCount += 1;
        return openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onCreate: (Database db, int version) async {},
        );
      }

      final String result = await withSqfliteDb<String>(
        open: open,
        getCached: () => cached,
        setCached: (Database? db) => cached = db,
        action: (Database db) async {
          actionCount += 1;
          if (actionCount == 1) {
            throw _TestDatabaseException('database_closed');
          }
          return 'ok';
        },
      );

      expect(result, 'ok');
      expect(actionCount, 2);
      expect(openCount, 2);
      await cached!.close();
    });

    test('rethrows non-database_closed DatabaseException', () async {
      Database? cached;

      await expectLater(
        withSqfliteDb<void>(
          open: () => openDatabase(
            inMemoryDatabasePath,
            version: 1,
            onCreate: (Database db, int version) async {},
          ),
          getCached: () => cached,
          setCached: (Database? db) => cached = db,
          action: (_) async {
            throw _TestDatabaseException('no such table: missing');
          },
        ),
        throwsA(isA<DatabaseException>()),
      );

      if (cached?.isOpen ?? false) {
        await cached!.close();
      }
    });
  });
}
