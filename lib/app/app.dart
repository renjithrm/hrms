import 'package:rebs_hrms/policies/attendance_policy.dart';
import 'package:rebs_hrms/policies/geofence_policy.dart';
import 'package:rebs_hrms/policies/leave_policy.dart';
import 'package:rebs_hrms/services/api_service.dart';
import 'package:rebs_hrms/services/app_lifecycle_service.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/services/connectivity_service.dart';
import 'package:rebs_hrms/services/database_service.dart';
import 'package:rebs_hrms/services/logger_service.dart';
import 'package:rebs_hrms/ui/views/startup/startup_view.dart';
import 'package:rebs_hrms/services/dev_settings_service.dart';
import 'package:rebs_hrms/services/employee_service.dart';
import 'package:rebs_hrms/ui/views/dev_settings/dev_settings_view.dart';
import 'package:rebs_hrms/ui/views/main/main_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:rebs_hrms/services/outbox_service.dart';
import 'package:rebs_hrms/services/attendance_service.dart';
import 'package:rebs_hrms/services/leave_service.dart';
import 'package:rebs_hrms/services/location_service.dart';
import 'package:rebs_hrms/ui/bottom_sheets/location_permission/location_permission_sheet.dart';
import 'package:rebs_hrms/ui/bottom_sheets/attendance_result/attendance_result_sheet.dart';
import 'package:rebs_hrms/services/sync_service.dart';
import 'package:rebs_hrms/ui/bottom_sheets/sync_queue/sync_queue_sheet.dart';
import 'package:rebs_hrms/ui/views/apply_leave/apply_leave_view.dart';
import 'package:rebs_hrms/ui/views/leave_submitted/leave_submitted_view.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: StartupView, initial: true),
    MaterialRoute(page: MainView),
    MaterialRoute(page: DevSettingsView),
    MaterialRoute(page: ApplyLeaveView),
    MaterialRoute(page: LeaveSubmittedView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: SnackbarService),
    // Infrastructure
    LazySingleton(classType: ClockService),
    LazySingleton(classType: LoggerService),
    InitializableSingleton(classType: DatabaseService),
    LazySingleton(classType: ApiService),
    LazySingleton(classType: ConnectivityService),
    LazySingleton(classType: AppLifecycleService),
    // Business rules
    LazySingleton(classType: AttendancePolicy),
    LazySingleton(classType: GeofencePolicy),
    LazySingleton(classType: LeavePolicy),
    // Domain
    LazySingleton(classType: EmployeeService),
    LazySingleton(classType: DevSettingsService),
    LazySingleton(classType: OutboxService),
    LazySingleton(classType: AttendanceService),
    LazySingleton(classType: LeaveService),
    LazySingleton(classType: LocationService),
    LazySingleton(classType: SyncService),
// @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: LocationPermissionSheet),
    StackedBottomsheet(classType: AttendanceResultSheet),
    StackedBottomsheet(classType: SyncQueueSheet),
// @stacked-bottom-sheet
  ],
)
class App {}
