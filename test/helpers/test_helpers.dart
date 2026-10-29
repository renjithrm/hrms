import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/models/attendance_day.dart';
import 'package:rebs_hrms/models/attendance_outcome.dart';
import 'package:rebs_hrms/models/attendance_rule_violation.dart';
import 'package:rebs_hrms/models/location_failure.dart';
import 'package:rebs_hrms/models/location_reading.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/policies/attendance_policy.dart';
import 'package:rebs_hrms/policies/geofence_policy.dart';
import 'package:rebs_hrms/policies/leave_policy.dart';
import 'package:rebs_hrms/services/api_service.dart';
import 'package:rebs_hrms/services/app_lifecycle_service.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/services/connectivity_service.dart';
import 'package:rebs_hrms/services/database_service.dart';
import 'package:rebs_hrms/services/logger_service.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:rebs_hrms/services/employee_service.dart';
import 'package:rebs_hrms/services/dev_settings_service.dart';
import 'package:rebs_hrms/services/outbox_service.dart';
import 'package:rebs_hrms/services/attendance_service.dart';
import 'package:rebs_hrms/services/leave_service.dart';
import 'package:rebs_hrms/services/location_service.dart';
import 'package:rebs_hrms/services/sync_service.dart';
import 'package:rebs_hrms/models/sync_summary.dart';
// @stacked-import

import 'test_helpers.mocks.dart';

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<NavigationService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<BottomSheetService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<DialogService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<SnackbarService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<ClockService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<LoggerService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<DatabaseService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<ApiService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<ConnectivityService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<AppLifecycleService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<AttendancePolicy>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<GeofencePolicy>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<LeavePolicy>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<EmployeeService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<DevSettingsService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<OutboxService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<AttendanceService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<LeaveService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<LocationService>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<SyncService>(onMissingStub: OnMissingStub.returnDefault),
// @stacked-mock-spec
  ],
)
void registerServices() {
  // Mockito needs a placeholder for sealed return types it cannot invent.
  provideDummy<LocationReading>(
    const LocationUnreadable(LocationFailure.unavailable),
  );
  provideDummy<SyncSummary>(const SyncAllSynced());
  provideDummy<({List<AttendanceDay> days, DateTime? updatedAt})>(
    (days: const <AttendanceDay>[], updatedAt: null),
  );
  provideDummy<AttendanceOutcome>(
    const AttendanceRefused(AttendanceRuleViolation.alreadyCheckedIn),
  );
  getAndRegisterNavigationService();
  getAndRegisterBottomSheetService();
  getAndRegisterDialogService();
  getAndRegisterSnackbarService();
  getAndRegisterClockService();
  getAndRegisterLoggerService();
  getAndRegisterDatabaseService();
  getAndRegisterApiService();
  getAndRegisterConnectivityService();
  getAndRegisterAppLifecycleService();
  getAndRegisterAttendancePolicy();
  getAndRegisterGeofencePolicy();
  getAndRegisterLeavePolicy();
  getAndRegisterEmployeeService();
  getAndRegisterDevSettingsService();
  getAndRegisterOutboxService();
  getAndRegisterAttendanceService();
  getAndRegisterLeaveService();
  getAndRegisterLocationService();
  getAndRegisterSyncService();
// @stacked-mock-register
}

MockNavigationService getAndRegisterNavigationService() {
  _removeRegistrationIfExists<NavigationService>();
  final service = MockNavigationService();
  locator.registerSingleton<NavigationService>(service);
  return service;
}

MockBottomSheetService getAndRegisterBottomSheetService<T>({
  SheetResponse<T>? showCustomSheetResponse,
}) {
  _removeRegistrationIfExists<BottomSheetService>();
  final service = MockBottomSheetService();

  when(
    service.showCustomSheet<T, T>(
      enableDrag: anyNamed('enableDrag'),
      enterBottomSheetDuration: anyNamed('enterBottomSheetDuration'),
      exitBottomSheetDuration: anyNamed('exitBottomSheetDuration'),
      ignoreSafeArea: anyNamed('ignoreSafeArea'),
      isScrollControlled: anyNamed('isScrollControlled'),
      barrierDismissible: anyNamed('barrierDismissible'),
      additionalButtonTitle: anyNamed('additionalButtonTitle'),
      variant: anyNamed('variant'),
      title: anyNamed('title'),
      hasImage: anyNamed('hasImage'),
      imageUrl: anyNamed('imageUrl'),
      showIconInMainButton: anyNamed('showIconInMainButton'),
      mainButtonTitle: anyNamed('mainButtonTitle'),
      showIconInSecondaryButton: anyNamed('showIconInSecondaryButton'),
      secondaryButtonTitle: anyNamed('secondaryButtonTitle'),
      showIconInAdditionalButton: anyNamed('showIconInAdditionalButton'),
      takesInput: anyNamed('takesInput'),
      barrierColor: anyNamed('barrierColor'),
      barrierLabel: anyNamed('barrierLabel'),
      customData: anyNamed('customData'),
      data: anyNamed('data'),
      description: anyNamed('description'),
    ),
  ).thenAnswer(
    (realInvocation) =>
        Future.value(showCustomSheetResponse ?? SheetResponse<T>()),
  );

  locator.registerSingleton<BottomSheetService>(service);
  return service;
}

MockDialogService getAndRegisterDialogService() {
  _removeRegistrationIfExists<DialogService>();
  final service = MockDialogService();
  locator.registerSingleton<DialogService>(service);
  return service;
}

MockSnackbarService getAndRegisterSnackbarService() {
  _removeRegistrationIfExists<SnackbarService>();
  final service = MockSnackbarService();
  locator.registerSingleton<SnackbarService>(service);
  return service;
}

MockClockService getAndRegisterClockService() {
  _removeRegistrationIfExists<ClockService>();
  final service = MockClockService();
  locator.registerSingleton<ClockService>(service);
  return service;
}

MockLoggerService getAndRegisterLoggerService() {
  _removeRegistrationIfExists<LoggerService>();
  final service = MockLoggerService();
  locator.registerSingleton<LoggerService>(service);
  return service;
}

MockDatabaseService getAndRegisterDatabaseService() {
  _removeRegistrationIfExists<DatabaseService>();
  final service = MockDatabaseService();
  locator.registerSingleton<DatabaseService>(service);
  return service;
}

MockApiService getAndRegisterApiService() {
  _removeRegistrationIfExists<ApiService>();
  final service = MockApiService();
  locator.registerSingleton<ApiService>(service);
  return service;
}

MockConnectivityService getAndRegisterConnectivityService() {
  _removeRegistrationIfExists<ConnectivityService>();
  final service = MockConnectivityService();
  locator.registerSingleton<ConnectivityService>(service);
  return service;
}

MockAppLifecycleService getAndRegisterAppLifecycleService() {
  _removeRegistrationIfExists<AppLifecycleService>();
  final service = MockAppLifecycleService();
  locator.registerSingleton<AppLifecycleService>(service);
  return service;
}

MockAttendancePolicy getAndRegisterAttendancePolicy() {
  _removeRegistrationIfExists<AttendancePolicy>();
  final service = MockAttendancePolicy();
  locator.registerSingleton<AttendancePolicy>(service);
  return service;
}

MockGeofencePolicy getAndRegisterGeofencePolicy() {
  _removeRegistrationIfExists<GeofencePolicy>();
  final service = MockGeofencePolicy();
  locator.registerSingleton<GeofencePolicy>(service);
  return service;
}

MockLeavePolicy getAndRegisterLeavePolicy() {
  _removeRegistrationIfExists<LeavePolicy>();
  final service = MockLeavePolicy();
  locator.registerSingleton<LeavePolicy>(service);
  return service;
}

MockEmployeeService getAndRegisterEmployeeService() {
  _removeRegistrationIfExists<EmployeeService>();
  final service = MockEmployeeService();
  locator.registerSingleton<EmployeeService>(service);
  return service;
}

MockDevSettingsService getAndRegisterDevSettingsService() {
  _removeRegistrationIfExists<DevSettingsService>();
  final service = MockDevSettingsService();
  locator.registerSingleton<DevSettingsService>(service);
  return service;
}

MockOutboxService getAndRegisterOutboxService() {
  _removeRegistrationIfExists<OutboxService>();
  final service = MockOutboxService();
  locator.registerSingleton<OutboxService>(service);
  return service;
}

MockAttendanceService getAndRegisterAttendanceService() {
  _removeRegistrationIfExists<AttendanceService>();
  final service = MockAttendanceService();
  locator.registerSingleton<AttendanceService>(service);
  return service;
}

MockLeaveService getAndRegisterLeaveService() {
  _removeRegistrationIfExists<LeaveService>();
  final service = MockLeaveService();
  locator.registerSingleton<LeaveService>(service);
  return service;
}

MockLocationService getAndRegisterLocationService() {
  _removeRegistrationIfExists<LocationService>();
  final service = MockLocationService();
  locator.registerSingleton<LocationService>(service);
  return service;
}

MockSyncService getAndRegisterSyncService() {
  _removeRegistrationIfExists<SyncService>();
  final service = MockSyncService();
  locator.registerSingleton<SyncService>(service);
  return service;
}
// @stacked-mock-create

void _removeRegistrationIfExists<T extends Object>() {
  if (locator.isRegistered<T>()) {
    locator.unregister<T>();
  }
}
