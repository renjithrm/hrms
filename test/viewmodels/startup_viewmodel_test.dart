import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/app/app.router.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/ui/views/startup/startup_viewmodel.dart';

import '../helpers/fixtures.dart';
import '../helpers/navigation_matchers.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('StartupViewModel -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    test('opens the main screen from cache and refreshes in background',
        () async {
      final navigation = getAndRegisterNavigationService();
      final employees = getAndRegisterEmployeeService();
      when(employees.loadCached()).thenAnswer((_) async => testEmployee);
      when(employees.refresh()).thenAnswer((_) async => testEmployee);

      final model = StartupViewModel();
      await model.runStartupLogic();

      verifyReplacedWith(navigation, Routes.mainView);
      verify(employees.refresh()).called(1);
      expect(model.hasError, isFalse);
    });

    test('retries interrupted sends and starts syncing before opening',
        () async {
      final navigation = getAndRegisterNavigationService();
      final employees = getAndRegisterEmployeeService();
      final outbox = getAndRegisterOutboxService();
      final sync = getAndRegisterSyncService();
      when(employees.loadCached()).thenAnswer((_) async => testEmployee);
      when(outbox.resetStuckSyncing()).thenAnswer((_) async => 1);
      when(sync.start()).thenAnswer((_) async {});

      await StartupViewModel().runStartupLogic();

      verifyInOrder([outbox.resetStuckSyncing(), sync.start()]);
      verifyReplacedWith(navigation, Routes.mainView);
    });

    test('opens even when the background refresh fails', () async {
      final navigation = getAndRegisterNavigationService();
      final employees = getAndRegisterEmployeeService();
      when(employees.loadCached()).thenAnswer((_) async => testEmployee);
      when(employees.refresh()).thenThrow(const OfflineException());

      final model = StartupViewModel();
      await model.runStartupLogic();

      verifyReplacedWith(navigation, Routes.mainView);
      expect(model.hasError, isFalse);
    });

    test('first launch waits for the network, then opens', () async {
      final navigation = getAndRegisterNavigationService();
      final employees = getAndRegisterEmployeeService();
      when(employees.loadCached()).thenAnswer((_) async => null);
      when(employees.refresh()).thenAnswer((_) async => testEmployee);

      await StartupViewModel().runStartupLogic();

      verifyReplacedWith(navigation, Routes.mainView);
    });

    test('first launch offline shows an error and stays put', () async {
      final navigation = getAndRegisterNavigationService();
      final employees = getAndRegisterEmployeeService();
      when(employees.loadCached()).thenAnswer((_) async => null);
      when(employees.refresh()).thenThrow(const OfflineException());

      final model = StartupViewModel();
      await model.runStartupLogic();

      expect(model.hasError, isTrue);
      expect(model.isBusy, isFalse);
      expect(model.errorMessage, AppStrings.offline);
      verifyNeverReplacedWith(navigation, Routes.mainView);
    });
  });
}
