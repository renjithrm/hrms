// lib/ui/bottom_sheets/attendance_result/attendance_result_sheet_model.dart

import 'dart:async';

import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../constants/app_strings.dart';
import '../../../models/attendance_event_type.dart';
import '../../../models/attendance_result.dart';

/// Confirms a check-in or check-out and closes itself after a few seconds.
class AttendanceResultSheetModel extends BaseViewModel {
  /// Creates the model for [result].
  AttendanceResultSheetModel(this.result);

  /// How long the sheet stays open on its own.
  static const Duration autoCloseAfter = Duration(seconds: 4);

  /// What happened.
  final AttendanceResult result;

  Timer? _autoClose;
  bool _isClosed = false;

  /// "Checked in" or "Checked out".
  String get title => result.type == AttendanceEventType.checkIn
      ? AppStrings.statusCheckedIn
      : AppStrings.statusCheckedOut;

  /// "09:02 · Infopark Phase 1".
  String get timeAndPlace =>
      AppStrings.resultTimeAndPlace(result.timeLabel, result.placeLabel);

  /// Whether the server has it.
  bool get isSynced => result.isSynced;

  /// "Synced with REBS" or "Saved on this phone".
  String get syncLabel =>
      isSynced ? AppStrings.resultSynced : AppStrings.resultSaved;

  /// One line explaining [syncLabel].
  String get syncDetail =>
      isSynced ? AppStrings.resultSyncedDetail : AppStrings.resultSavedDetail;

  /// Starts the timer that closes the sheet after [autoCloseAfter].
  void startAutoClose(void Function(SheetResponse) complete) {
    _autoClose ??= Timer(autoCloseAfter, () => close(complete));
  }

  /// Closes the sheet once, whether from the button or the timer.
  void close(void Function(SheetResponse) complete) {
    if (_isClosed) return;
    _isClosed = true;
    _autoClose?.cancel();
    complete(SheetResponse(confirmed: true));
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }
}
