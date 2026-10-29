// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedLocatorGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs, implementation_imports, depend_on_referenced_packages

import 'package:stacked_services/src/bottom_sheet/bottom_sheet_service.dart';
import 'package:stacked_services/src/dialog/dialog_service.dart';
import 'package:stacked_services/src/navigation/navigation_service.dart';
import 'package:stacked_services/src/snackbar/snackbar_service.dart';
import 'package:stacked_shared/stacked_shared.dart';

import '../policies/attendance_policy.dart';
import '../policies/geofence_policy.dart';
import '../policies/leave_policy.dart';
import '../services/api_service.dart';
import '../services/app_lifecycle_service.dart';
import '../services/attendance_service.dart';
import '../services/clock_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_service.dart';
import '../services/dev_settings_service.dart';
import '../services/employee_service.dart';
import '../services/leave_service.dart';
import '../services/location_service.dart';
import '../services/logger_service.dart';
import '../services/outbox_service.dart';
import '../services/sync_service.dart';

final locator = StackedLocator.instance;

Future<void> setupLocator(
    {String? environment, EnvironmentFilter? environmentFilter}) async {
// Register environments
  locator.registerEnvironment(
      environment: environment, environmentFilter: environmentFilter);

// Register dependencies
  locator.registerLazySingleton(() => BottomSheetService());
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => SnackbarService());
  locator.registerLazySingleton(() => ClockService());
  locator.registerLazySingleton(() => LoggerService());
  final databaseService = DatabaseService();
  await databaseService.init();
  locator.registerSingleton(databaseService);

  locator.registerLazySingleton(() => ApiService());
  locator.registerLazySingleton(() => ConnectivityService());
  locator.registerLazySingleton(() => AppLifecycleService());
  locator.registerLazySingleton(() => AttendancePolicy());
  locator.registerLazySingleton(() => GeofencePolicy());
  locator.registerLazySingleton(() => LeavePolicy());
  locator.registerLazySingleton(() => EmployeeService());
  locator.registerLazySingleton(() => DevSettingsService());
  locator.registerLazySingleton(() => OutboxService());
  locator.registerLazySingleton(() => AttendanceService());
  locator.registerLazySingleton(() => LeaveService());
  locator.registerLazySingleton(() => LocationService());
  locator.registerLazySingleton(() => SyncService());
}
