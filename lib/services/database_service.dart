// lib/services/database_service.dart

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:stacked/stacked_annotations.dart';

/// Opens the local SQLite database and owns its schema.
///
/// Registered as an initializable singleton, so the database is open before
/// any other service runs.
class DatabaseService implements InitializableDependency {
  /// Creates the service. [path] and [factory] exist for tests, which use an
  /// in-memory or temporary file through `sqflite_common_ffi`.
  DatabaseService({String? path, DatabaseFactory? factory})
      : _path = path,
        _factory = factory;

  /// Current schema version.
  static const int schemaVersion = 1;

  /// File name inside the app's database directory.
  static const String fileName = 'rebs_hrms.db';

  final String? _path;
  final DatabaseFactory? _factory;
  Database? _database;

  /// The open database. Throws if [init] has not completed.
  Database get db {
    final database = _database;
    if (database == null) {
      throw StateError('DatabaseService.init() has not completed');
    }
    return database;
  }

  @override
  Future<void> init() async {
    if (_database != null) return;
    final factory = _factory ?? databaseFactory;
    final path = _path ?? p.join(await factory.getDatabasesPath(), fileName);
    _database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _createV1(db),
      ),
    );
  }

  /// Reads a timestamp saved with [writeTimestamp], such as when a cache was
  /// last refreshed.
  Future<DateTime?> readTimestamp(String key) async {
    final rows = await db.query(
      'sync_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.parse(rows.single['value'] as String);
  }

  /// Saves [value] under [key] in `sync_meta`, inside [executor] so it can
  /// share a transaction with the data it describes.
  Future<void> writeTimestamp(
    DatabaseExecutor executor,
    String key,
    DateTime value,
  ) =>
      executor.insert(
        'sync_meta',
        {'key': key, 'value': value.toUtc().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// Closes the database. Used by tests to simulate an app restart.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _createV1(Database db) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE employee (
          id TEXT PRIMARY KEY,
          json TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )''')
      ..execute('''
        CREATE TABLE attendance (
          work_date TEXT PRIMARY KEY,
          month TEXT NOT NULL,
          json TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )''')
      ..execute('CREATE INDEX attendance_month ON attendance (month)')
      ..execute('''
        CREATE TABLE leave_balance (
          type TEXT PRIMARY KEY,
          json TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )''')
      ..execute('''
        CREATE TABLE leave_requests (
          id TEXT PRIMARY KEY,
          start_date TEXT NOT NULL,
          status TEXT NOT NULL,
          json TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )''')
      // The outbox is the source of truth for attendance taken on this
      // device. seq gives the send order; event_id is the idempotency key.
      ..execute('''
        CREATE TABLE outbox (
          seq INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id TEXT NOT NULL UNIQUE,
          type TEXT NOT NULL,
          work_date TEXT NOT NULL,
          occurred_at TEXT NOT NULL,
          lat REAL NOT NULL,
          lng REAL NOT NULL,
          accuracy_m REAL NOT NULL,
          status TEXT NOT NULL,
          attempts INTEGER NOT NULL DEFAULT 0,
          next_attempt_at TEXT,
          last_error TEXT,
          dismissed INTEGER NOT NULL DEFAULT 0
        )''')
      // The database itself refuses a second check-in or check-out for the
      // same day, even if application code has a bug.
      ..execute('''
        CREATE UNIQUE INDEX outbox_one_per_day
          ON outbox (work_date, type) WHERE status != 'REJECTED'
        ''')
      ..execute('''
        CREATE TABLE sync_meta (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )''');
    await batch.commit(noResult: true);
  }
}
