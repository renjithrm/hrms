// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedBottomsheetGenerator
// **************************************************************************

import 'package:stacked_services/stacked_services.dart';

import 'app.locator.dart';
import '../ui/bottom_sheets/attendance_result/attendance_result_sheet.dart';
import '../ui/bottom_sheets/location_permission/location_permission_sheet.dart';
import '../ui/bottom_sheets/sync_queue/sync_queue_sheet.dart';

enum BottomSheetType {
  locationPermission,
  attendanceResult,
  syncQueue,
}

void setupBottomSheetUi() {
  final bottomsheetService = locator<BottomSheetService>();

  final Map<BottomSheetType, SheetBuilder> builders = {
    BottomSheetType.locationPermission: (context, request, completer) =>
        LocationPermissionSheet(request: request, completer: completer),
    BottomSheetType.attendanceResult: (context, request, completer) =>
        AttendanceResultSheet(request: request, completer: completer),
    BottomSheetType.syncQueue: (context, request, completer) =>
        SyncQueueSheet(request: request, completer: completer),
  };

  bottomsheetService.setCustomSheetBuilders(builders);
}
