import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/services/database_service.dart';
import 'package:rebs_hrms/services/employee_service.dart';

import '../helpers/database_test_helper.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('EmployeeService -', () {
    late DatabaseService database;

    setUp(() async {
      registerServices();
      database = await openTestDatabase();
      locator
        ..unregister<DatabaseService>()
        ..registerSingleton<DatabaseService>(database)
        ..unregister<ClockService>()
        ..registerSingleton<ClockService>(
          ClockService(now: () => DateTime.utc(2026, 10, 28, 4)),
        );
    });

    tearDown(() async {
      await database.close();
      await locator.reset();
    });

    test('loadCached returns null before the first refresh', () async {
      expect(await EmployeeService().loadCached(), isNull);
    });

    test('refresh stores the employee for the next launch', () async {
      final api = getAndRegisterApiService();
      when(api.fetchEmployee()).thenAnswer((_) async => testEmployee);

      await EmployeeService().refresh();
      final nextLaunch = EmployeeService();
      final cached = await nextLaunch.loadCached();

      expect(cached?.id, 'EMP-1042');
      expect(nextLaunch.lastUpdated, DateTime.utc(2026, 10, 28, 4));
    });

    test('a failed refresh throws and keeps the cached copy', () async {
      final api = getAndRegisterApiService();
      when(api.fetchEmployee()).thenAnswer((_) async => testEmployee);
      final service = EmployeeService();
      await service.refresh();

      when(api.fetchEmployee()).thenThrow(const OfflineException());
      await expectLater(service.refresh(), throwsA(isA<OfflineException>()));
      expect(service.employee?.name, 'Anjali Nair');
    });
  });
}
