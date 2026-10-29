// lib/constants/app_strings.dart

/// Every user-visible string. Functions are used where a value is inserted.
abstract final class AppStrings {
  // App
  static const String appName = 'REBS Workspace';
  static const String devFlavorBanner = 'DEV';
  static const String loading = 'Loading your workspace…';

  // Attendance rules
  static const String alreadyCheckedIn = 'You have already checked in today.';
  static const String checkOutBeforeCheckIn =
      'Check in first. You can check out after that.';
  static const String alreadyCheckedOut = 'You have already checked out today.';
  static String outsideOffice(int distanceMetres, int radiusMetres) =>
      'You are $distanceMetres m from the office. Attendance works within '
      '$radiusMetres m.';
  static String inaccurateLocation(int accuracyMetres) =>
      'Your location is only accurate to $accuracyMetres m. Move near a '
      'window or outside and try again.';

  // Leave rules
  static const String leaveDatesMissing = 'Choose a start and an end date.';
  static const String leaveStartBeforeToday =
      'Leave can start today at the earliest.';
  static const String leaveEndBeforeStart =
      'The end date must be on or after the start date.';
  static String leaveReasonTooShort(int count) =>
      'Add a few more words (at least 10 characters, spaces don\'t count). '
      '$count so far.';
  static String leaveExceedsBalance(
    int requested,
    int available,
    String type,
  ) =>
      '${leaveDays(requested)} requested, but you have $available '
      '${type.toLowerCase()} ${available == 1 ? 'day' : 'days'} left. '
      'Shorten the range or choose another type.';
  static String leaveOverlaps(String status, String range) =>
      'These dates overlap your ${status.toLowerCase()} request for $range. '
      'Choose other days, or cancel that request first.';

  // Network
  static const String offline =
      'You\'re offline. Check your connection and try again.';
  static const String timeout =
      'The server took too long to answer. Try again.';
  static String serverError(int statusCode) =>
      'The server returned an error ($statusCode). Try again in a moment.';
  static const String unexpectedError =
      'Something went wrong. Try again in a moment.';

  // Startup
  static const String startupFailedTitle = 'Couldn\'t reach REBS';
  static const String startupFailedHint =
      'Your details haven\'t been downloaded yet, so the app needs a '
      'connection the first time. Check that the mock API is running.';
  static const String tryAgain = 'Try again';

  // Navigation
  static const String tabToday = 'Today';
  static const String tabAttendance = 'Attendance';
  static const String tabLeave = 'Leave';

  // Sync pill
  static const String syncSynced = 'Synced';
  static const String syncOffline = 'Offline';
  static const String syncInProgress = 'Syncing';
  static String syncWaiting(int count) => '$count waiting';
  static const String syncNeedsAttention = 'Needs attention';

  // Today
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';
  static const String statusNotCheckedIn = 'Not checked in';
  static const String statusCheckedIn = 'Checked in';
  static const String statusCheckedOut = 'Checked out';
  static String shiftLine(String start, String end, String zone) =>
      'Shift $start – $end · $zone';
  static const String labelCheckedIn = 'Checked in';
  static const String labelCheckedOut = 'Checked out';
  static const String labelWorked = 'Worked';
  static const String timeMissing = '--:--';
  static const String leaveAvailable = 'Leave available';
  static String leaveOfTotal(int available, int total) =>
      '$available of $total left';
  static const String recentHeading = 'Recent';
  static const String recentEmptyTitle = 'No attendance yet';
  static const String recentEmptyMessage = 'Your check-ins will appear here.';
  static const String chipWaiting = 'Waiting';
  static String offlineBanner(String time) =>
      'You\'re offline. Showing data from $time.';
  static String refreshFailedBanner(String time) =>
      'Couldn\'t refresh. Showing data from $time.';
  static const String retry = 'Retry';
  static const String todayLoadFailedTitle = 'Couldn\'t load your dashboard';
  static String hoursMinutes(int hours, int minutes) => '${hours}h ${minutes}m';

  // Location tile
  static const String locationChecking = 'Checking your location…';
  static const String locationCheckingDetail = 'Getting a GPS fix, up to 10 s';
  static const String locationInside = 'You\'re at the office';
  static String locationInsideDetail(
          int distance, String office, int accuracy) =>
      '$distance m from $office · accuracy ±$accuracy m';
  static String locationOutside(int distance) =>
      'You\'re $distance m from the office';
  static String locationOutsideDetail(int radius, String office) =>
      'Check-in opens within $radius m of $office. Move closer and it '
      'unlocks automatically.';
  static const String locationImprecise = 'Location isn\'t precise enough';
  static String locationImpreciseDetail(int accuracy) =>
      'Accuracy is ±$accuracy m. Move near a window or outside and try again.';
  static const String locationDenied = 'Location permission needed';
  static const String locationDeniedDetail =
      'Allow location so the app can confirm you\'re at the office.';
  static const String locationBlocked = 'Location is turned off for REBS';
  static const String locationBlockedDetail =
      'Turn it back on in Settings to check in or out.';
  static const String locationServiceOff = 'Location services are off';
  static const String locationServiceOffDetail =
      'Turn on location in your phone\'s settings to check in or out.';
  static const String locationUnavailable = 'Couldn\'t get your location';
  static const String locationUnavailableDetail =
      'No GPS fix within 10 s. Try again near a window.';
  static const String actionUpdateLocation = 'Update my location';
  static const String actionAllowLocation = 'Allow location';
  static const String actionFix = 'Fix';
  static const String mapOfficeLabel = 'Office';
  static const String mapYouLabel = 'You';

  // Check-in and check-out
  static const String slideToCheckIn = 'Slide to check in';
  static const String slideToCheckOut = 'Slide to check out';
  static const String slideLocked = 'Available at the office';
  static String ringCaption(int hours) => 'of ${hours}h shift';
  static String elapsed(int hours, int minutes, int seconds) =>
      '$hours:${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
  static String workedToday(String worked) => 'Worked $worked today';

  // Attendance month
  static const List<String> weekdayInitials = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];
  static const String dayPresent = 'Present';
  static const String dayWaiting = 'Waiting to sync';
  static const String dayLeave = 'On leave';
  static const String dayWeekend = 'Weekend';
  static const String dayToday = 'Not checked in yet';
  static const String dayAbsent = 'No attendance';
  static const String dayUpcoming = 'Upcoming';
  static String dayLeaveDetail(String type) => '$type leave';
  static const String summaryPresent = 'Present';
  static String summaryDays(int count) => count == 1 ? '1 day' : '$count days';
  static const String summaryAverage = 'Avg day';
  static const String previousMonth = 'Previous month';
  static const String nextMonth = 'Next month';
  static const String showAsList = 'Show as list';
  static const String showAsCalendar = 'Show as calendar';
  static String emptyMonthTitle(String month) => 'No attendance in $month';
  static const String emptyMonthMessage =
      'Days you check in on will show up here.';
  static const String monthLoadFailedTitle = 'Couldn\'t load this month';
  static String calendarDayLabel(String date, String status) =>
      '$date, $status';

  // Leave overview
  static const String applyForLeave = 'Apply for leave';
  static const String needsConnection = 'Needs a connection';
  static String leaveOnHold(int days) => days == 1
      ? '1 day on hold in a pending request'
      : '$days days on hold in pending requests';
  static const String filterAll = 'All';
  static const String leavePending = 'Pending';
  static const String leaveApproved = 'Approved';
  static const String leaveRejected = 'Rejected';
  static String filterWithCount(String label, int count) => '$label $count';
  static String leaveDays(int days) => days == 1 ? '1 day' : '$days days';
  static String leaveRequestTitle(String type, String range) =>
      '$type · $range';
  static String leaveRequestDetail(String days, String reason) =>
      '$days · $reason';
  static const String leaveEmptyTitle = 'No leave requests yet';
  static const String leaveEmptyMessage =
      'Requests you make will show up here.';
  static String leaveFilterEmpty(String status) =>
      'No ${status.toLowerCase()} requests';
  static const String leaveLoadFailedTitle = 'Couldn\'t load your leave';
  static const String leaveRequestsHeading = 'Requests';

  // Apply leave, step 1
  static const String applyStepDates = '1 of 2';
  static const String applyStepReview = '2 of 2';
  static const String leaveTypeHeading = 'Type';
  static const String leaveDatesHeading = 'Dates';
  static String leaveTypeAvailable(int available, int total) =>
      '$available of $total left';
  static const String leavePickStart = 'Tap the first day of your leave.';
  static String leavePickEnd(String start) =>
      'Starts $start. Now tap the last day of your leave.';
  static String leaveRangeSummary(String range, int days) =>
      '$range · ${leaveDays(days)}';
  static String leaveLeftAfter(String type, int left, int total) =>
      '$type left after this: $left of $total';
  static const String continueLabel = 'Continue';
  static const String calendarLegendPending = 'Pending request';
  static const String calendarLegendApproved = 'Approved leave';
  static String leaveDayLabel(String date, String state) =>
      state.isEmpty ? date : '$date, $state';
  static const String leaveDaySelected = 'selected';
  static const String leaveDayUnavailable = 'not available';

  // Apply leave, step 2
  static const String reviewHeading = 'Review';
  static const String summaryType = 'Type';
  static const String summaryDates = 'Dates';
  static const String summaryDaysLabel = 'Days';
  static String summaryLeftAfter(String type) => '$type left after this';
  static String calendarDays(int days) =>
      days == 1 ? '1 calendar day' : '$days calendar days';
  static String ofTotal(int value, int total) => '$value of $total';
  static const String reasonLabel = 'Reason';
  static const String reasonHint = 'For example: family function in Thrissur';
  static const String reasonHelper =
      'Spaces don\'t count toward the 10-character minimum.';
  static String reasonCount(int count) =>
      count == 1 ? '1 character' : '$count characters';
  static const String reasonOk = 'Looks good';
  static const String changeDates = 'Change dates';
  static const String submitRequest = 'Submit request';
  static const String submitting = 'Submitting…';
  static const String leaveNotAcceptedTitle =
      'REBS didn\'t accept this request.';
  static String leaveNotAcceptedDates(String reason) =>
      '$reason Go back and pick other dates. Your reason is kept.';
  static const String leaveSubmitTimeout =
      'REBS didn\'t answer in time, so the request may or may not have been '
      'saved. Check your requests before trying again.';

  // Leave submitted
  static const String requestSentTitle = 'Request sent';
  static const String requestSentMessage =
      'Your manager will review it. You\'ll see the decision in Leave.';
  static String leaveTypeTitle(String type) => '$type leave';
  static String summaryLeft(String type) => '$type left';
  static String balanceWithHold(int available, int total, int onHold) =>
      onHold == 0
          ? '$available of $total'
          : '$available of $total ($onHold on hold)';
  static const String backToLeave = 'Back to leave';

  // Attendance result sheet
  static const String resultSynced = 'Synced with REBS';
  static const String resultSaved = 'Saved on this phone';
  static const String resultSavedDetail =
      'It will reach REBS automatically when you\'re back online.';
  static const String resultSyncedDetail = 'Your manager can see it now.';
  static String resultTimeAndPlace(String time, String place) =>
      '$time · $place';
  static const String resultDone = 'Done';

  // Sync queue sheet
  static const String syncSheetTitle = 'Sync';
  static const String syncSheetAllDone = 'Everything is on the server.';
  static String syncSheetWaiting(int count) =>
      count == 1 ? '1 entry waiting to send' : '$count entries waiting to send';
  static const String syncSheetOffline =
      'You\'re offline. Waiting entries send when you reconnect.';
  static const String syncSheetEmpty = 'Nothing recorded on this phone yet.';
  static const String syncSheetHint = 'Long-press an entry to see its ID.';
  static const String syncNow = 'Sync now';
  static const String syncingNow = 'Syncing…';
  static const String eventCheckIn = 'Check-in';
  static const String eventCheckOut = 'Check-out';
  static String eventTitle(String type, String when) => '$type · $when';
  static const String eventWaiting = 'Waiting to send';
  static String eventRetryAt(String time) => 'Retrying at $time';
  static const String eventSending = 'Sending…';
  static const String eventSynced = 'Synced';
  static const String eventRejected = 'Not accepted';
  static String eventId(String id) => 'Event ID $id';
  static const String dismiss = 'Dismiss';

  // Location permission sheet
  static const String sheetWhyLocation =
      'Attendance only counts at the office, so the app checks your location '
      'at the moment you check in or out. It isn\'t tracked at other times.';
  static const String sheetOpenSettings = 'Open settings';
  static const String sheetOpenLocationSettings = 'Open location settings';
  static const String sheetTryAgain = 'Try again';
  static const String sheetNotNow = 'Not now';
  static const String sheetStepOpen = 'Tap Open settings below';
  static const String sheetStepPermissions = 'Go to Location';
  static const String sheetStepAllow =
      'Choose While Using the App, then come back';

  // Developer settings
  static const String devSettingsTitle = 'Developer settings';
  static const String devSettingsBadge = 'Dev flavour';
  static const String devLocationHeading = 'Location';
  static const String devScenarioHeading = 'Mock API scenario';
  static const String devConfigHeading = 'Configuration';
  static const String devResetMock = 'Reset mock data';
  static const String devResetDone = 'Mock data reset to the seed.';
  static const String devClearToday = 'Clear today\'s attendance';
  static const String devClearTodayHint =
      'Removes today\'s check-in and check-out on this phone and on the mock '
      'server, so you can check in again.';
  static const String devClearTodayDone = 'Today\'s attendance cleared.';
  static String devScenarioSet(String name) => 'Scenario set to $name.';
  static const String devOffice = 'Office';
  static const String devTimezone = 'Timezone';
  static const String devApi = 'API';
  static const String devOfficeUnknown = 'Not loaded yet';
  static const String devOpenHint = 'Long-press to open developer settings';
  static const String devPresetDeviceGps = 'Use device GPS';
  static const String devPresetAtOffice = 'At office · 0 m';
  static const String devPresetNearEdge = 'Near edge · 190 m';
  static const String devPresetOutside = 'Outside · 850 m';
  static const String devPresetUnavailable = 'GPS unavailable';
  static const String devPresetDenied = 'Permission denied';
  static const String devPresetBlocked = 'Permission blocked';
  static const String devMockUnreachable =
      'The mock API didn\'t answer. Start it with "dart run bin/server.dart" '
      'inside mock_server/.';
  static const String devMockOutdated =
      'The mock API doesn\'t know this action, so it is running older code. '
      'Stop it and start it again with "dart run bin/server.dart" inside '
      'mock_server/.';
}
