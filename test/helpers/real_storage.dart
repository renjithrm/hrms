import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/services/database_service.dart';
import 'package:rebs_hrms/services/outbox_service.dart';

import 'database_test_helper.dart';

/// Wednesday 28 Oct 2026, 09:30 in India.
final testNow = DateTime.utc(2026, 10, 28, 4);

/// Replaces the mocked database, clock and outbox with real ones backed by
/// an FFI SQLite database. Call after `registerServices()`.
Future<DatabaseService> useRealStorage({DateTime? now, String? path}) async {
  final database = await openTestDatabase(path: path);
  final clock =
      ClockService(now: () => now ?? testNow, timezone: 'Asia/Kolkata');
  locator
    ..unregister<DatabaseService>()
    ..registerSingleton<DatabaseService>(database)
    ..unregister<ClockService>()
    ..registerSingleton<ClockService>(clock)
    ..unregister<OutboxService>()
    ..registerSingleton<OutboxService>(OutboxService());
  return database;
}
