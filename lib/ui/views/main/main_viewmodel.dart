// lib/ui/views/main/main_viewmodel.dart

import 'package:stacked/stacked.dart';

/// Tracks the selected tab: Today, Attendance or Leave.
class MainViewModel extends IndexTrackingViewModel {
  /// Index of the Today tab.
  static const int todayTab = 0;

  /// Index of the Attendance tab.
  static const int attendanceTab = 1;

  /// Index of the Leave tab.
  static const int leaveTab = 2;

  /// Switches to the tab at [index].
  void selectTab(int index) => setIndex(index);
}
