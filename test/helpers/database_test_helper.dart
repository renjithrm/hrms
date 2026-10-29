import 'package:rebs_hrms/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Creates a [DatabaseService] backed by SQLite through FFI, so persistence
/// tests run on the development machine.
///
/// Pass a [path] to a temporary file to test closing and reopening; omit it
/// for a fresh in-memory database.
Future<DatabaseService> openTestDatabase({String? path}) async {
  sqfliteFfiInit();
  final service = DatabaseService(
    path: path ?? inMemoryDatabasePath,
    factory: databaseFactoryFfi,
  );
  await service.init();
  return service;
}
