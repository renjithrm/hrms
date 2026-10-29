// lib/ui/views/attendance/attendance_viewmodel.dart

import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.bottomsheets.dart';
import '../../../app/app.locator.dart';
import '../../../constants/app_strings.dart';
import '../../../extensions/date_time_extensions.dart';
import '../../../extensions/error_message_extension.dart';
import '../../../models/attendance_day.dart';
import '../../../models/calendar_day.dart';
import '../../../models/leave_request.dart';
import '../../../models/leave_status.dart';
import '../../../models/sync_summary.dart';
import '../../../services/attendance_service.dart';
import '../../../services/clock_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/leave_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/sync_service.dart';

/// Screen H: one month of attendance as a calendar (or a list), with a
/// summary and the selected day's detail. Months already viewed stay
/// readable offline.
class AttendanceViewModel extends ReactiveViewModel {
  final _attendanceService = locator<AttendanceService>();
  final _leaveService = locator<LeaveService>();
  final _connectivityService = locator<ConnectivityService>();
  final _clock = locator<ClockService>();
  final _logger = locator<LoggerService>();
  final _syncService = locator<SyncService>();
  final _bottomSheetService = locator<BottomSheetService>();

  final _monthFormat = DateFormat('MMMM yyyy');
  final _monthName = DateFormat('MMMM');
  final _dayFormat = DateFormat('EEE, d MMM');
  final _time = DateFormat('HH:mm');
  final _stamp = DateFormat('d MMM, HH:mm');

  late DateTime _month = _currentMonth;
  DateTime? _selected;
  List<AttendanceDay> _days = const [];
  DateTime? _updatedAt;
  bool _isListView = false;

  @override
  List<ListenableServiceMixin> get listenableServices => [
        _connectivityService,
        _leaveService,
        _syncService,
      ];

  /// Shows the current month from the cache, then refreshes it.
  Future<void> init() async {
    _selected = _clock.companyToday();
    _attendanceService.addListener(_onAttendanceChanged);
    await _readCache();
    await refresh();
  }

  @override
  void dispose() {
    _attendanceService.removeListener(_onAttendanceChanged);
    super.dispose();
  }

  /// What the sync pill shows.
  SyncSummary get syncSummary => _syncService.summary;

  /// Opens the sync queue sheet from the pill.
  Future<void> openSyncQueue() async {
    await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.syncQueue,
      isScrollControlled: true,
    );
  }

  // Month

  DateTime get _currentMonth {
    final today = _clock.companyToday();
    return DateTime.utc(today.year, today.month);
  }

  /// "October 2026".
  String get monthLabel => _monthFormat.format(_month);

  /// Whether a later month can be shown (not past the current month).
  bool get canGoNext => _month.isBefore(_currentMonth);

  /// Shows the month before.
  Future<void> previousMonth() =>
      _showMonth(DateTime.utc(_month.year, _month.month - 1));

  /// Shows the month after, up to the current month.
  Future<void> nextMonth() async {
    if (!canGoNext) return;
    await _showMonth(DateTime.utc(_month.year, _month.month + 1));
  }

  Future<void> _showMonth(DateTime month) async {
    _month = month;
    final today = _clock.companyToday();
    _selected =
        today.year == month.year && today.month == month.month ? today : null;
    _days = const [];
    _updatedAt = null;
    clearErrors();
    notifyListeners();
    await _readCache();
    await refresh();
  }

  /// Downloads the shown month. Used on open, on month change and by
  /// pull-to-refresh.
  Future<void> refresh() async {
    final month = _month;
    clearErrors();
    setBusy(true);
    try {
      await _attendanceService.refreshMonth(month.isoMonth);
    } catch (e, stackTrace) {
      _logger.error('Attendance month', e, stackTrace);
      if (month == _month) setError(e);
    } finally {
      setBusy(false);
    }
    await _readCache();
  }

  void _onAttendanceChanged() => _readCache();

  Future<void> _readCache() async {
    final month = _month;
    try {
      final cached = await _attendanceService.cachedMonth(month.isoMonth);
      if (month != _month) return;
      _days = cached.days;
      _updatedAt = cached.updatedAt;
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.error('Attendance month cache', e, stackTrace);
    }
  }

  // Screen state

  /// Whether this month has ever been downloaded.
  bool get hasCache => _updatedAt != null;

  /// First load of a month with nothing cached.
  bool get showLoading => isBusy && !hasCache && _days.isEmpty;

  /// Nothing cached and the download failed.
  bool get showFullError => hasError && !hasCache && _days.isEmpty;

  /// Message for the full error state.
  String get errorMessage {
    final Object? error = modelError;
    return error?.userMessage ?? AppStrings.unexpectedError;
  }

  /// Downloaded and no attendance at all this month.
  bool get showEmpty =>
      !showLoading && !showFullError && presentCount == 0 && hasCache;

  /// "No attendance in October".
  String get emptyTitle =>
      AppStrings.emptyMonthTitle(_monthName.format(_month));

  /// Banner over cached data that may be old, or null.
  String? get bannerMessage {
    final updated = _updatedAt;
    if (updated == null) return null;
    final stamp = _stamp.format(_clock.toCompany(updated));
    if (!_connectivityService.isOnline) return AppStrings.offlineBanner(stamp);
    if (hasError) return AppStrings.refreshFailedBanner(stamp);
    return null;
  }

  /// Whether the banner reports a failure rather than being offline.
  bool get isBannerAnError => hasError && _connectivityService.isOnline;

  // Calendar

  /// Empty cells before the 1st, for a grid that starts on Monday.
  int get leadingBlanks => _month.weekday - 1;

  /// Every day of the month.
  List<CalendarDay> get calendarDays {
    final byDate = {for (final day in _days) day.workDate: day};
    final approved = _leaveService.requests
        .where((r) => r.status == LeaveStatus.approved)
        .toList();
    final today = _clock.companyToday();
    final count = DateTime.utc(_month.year, _month.month + 1, 0).day;
    return [
      for (var d = 1; d <= count; d++)
        _calendarDay(
          DateTime.utc(_month.year, _month.month, d),
          today,
          byDate,
          approved,
        ),
    ];
  }

  CalendarDay _calendarDay(
    DateTime date,
    DateTime today,
    Map<String, AttendanceDay> byDate,
    List<LeaveRequest> approved,
  ) {
    final attendance = byDate[date.isoDate];
    LeaveRequest? leave;
    for (final request in approved) {
      if (!date.isBefore(request.startDate) && !date.isAfter(request.endDate)) {
        leave = request;
        break;
      }
    }
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final kind = switch (attendance) {
      AttendanceDay(checkInAt: _?) when attendance.isWaitingToSync =>
        CalendarDayKind.waiting,
      AttendanceDay(checkInAt: _?) => CalendarDayKind.present,
      _ when leave != null => CalendarDayKind.leave,
      _ when isWeekend => CalendarDayKind.weekend,
      _ when date == today => CalendarDayKind.today,
      _ when date.isAfter(today) => CalendarDayKind.upcoming,
      _ => CalendarDayKind.absent,
    };
    return CalendarDay(
      date: date,
      kind: kind,
      isToday: date == today,
      attendance: attendance,
      leave: leave,
    );
  }

  /// Whether [day] is the selected one.
  bool isSelected(CalendarDay day) => day.date == _selected;

  /// Selects [day] for the detail card.
  void selectDay(CalendarDay day) {
    _selected = day.date;
    notifyListeners();
  }

  /// The selected day, or null.
  CalendarDay? get selectedDay {
    final selected = _selected;
    if (selected == null) return null;
    for (final day in calendarDays) {
      if (day.date == selected) return day;
    }
    return null;
  }

  /// "Wed, 28 Oct".
  String dateLabelOf(CalendarDay day) => _dayFormat.format(day.date);

  /// Status word for a day, for the detail card, list and screen readers.
  String statusOf(CalendarDay day) => switch (day.kind) {
        CalendarDayKind.present => AppStrings.dayPresent,
        CalendarDayKind.waiting => AppStrings.dayWaiting,
        CalendarDayKind.leave =>
          AppStrings.dayLeaveDetail(day.leave?.type.label ?? ''),
        CalendarDayKind.weekend => AppStrings.dayWeekend,
        CalendarDayKind.today => AppStrings.dayToday,
        CalendarDayKind.absent => AppStrings.dayAbsent,
        CalendarDayKind.upcoming => AppStrings.dayUpcoming,
      };

  /// "Wed, 28 Oct, Present", for screen readers.
  String semanticsOf(CalendarDay day) =>
      AppStrings.calendarDayLabel(dateLabelOf(day), statusOf(day));

  /// Check-in time, or a dash.
  String checkInOf(CalendarDay day) => _format(day.attendance?.checkInAt);

  /// Check-out time, or a dash.
  String checkOutOf(CalendarDay day) => _format(day.attendance?.checkOutAt);

  /// "9h 34m", or a dash while the day is open.
  String workedOf(CalendarDay day) {
    final worked = day.attendance?.worked;
    if (worked == null) return AppStrings.timeMissing;
    return AppStrings.hoursMinutes(worked.inHours, worked.inMinutes % 60);
  }

  // Summary

  /// Days with a check-in this month.
  int get presentCount => _days.where((d) => d.checkInAt != null).length;

  /// "19 days".
  String get presentLabel => AppStrings.summaryDays(presentCount);

  /// Average length of complete days, "8h 58m", or a dash.
  String get averageDayLabel {
    final worked = [
      for (final day in _days)
        if (day.worked case final Duration w) w,
    ];
    if (worked.isEmpty) return AppStrings.timeMissing;
    final minutes =
        worked.fold<int>(0, (sum, w) => sum + w.inMinutes) ~/ worked.length;
    return AppStrings.hoursMinutes(minutes ~/ 60, minutes % 60);
  }

  // List view

  /// Whether the accessible list replaces the calendar.
  bool get isListView => _isListView;

  /// "Show as list" or "Show as calendar".
  String get viewToggleLabel =>
      _isListView ? AppStrings.showAsCalendar : AppStrings.showAsList;

  /// Switches between calendar and list.
  void toggleListView() {
    _isListView = !_isListView;
    notifyListeners();
  }

  /// Days up to today that have something to say, newest first.
  List<CalendarDay> get listDays => calendarDays
      .where(
        (d) =>
            d.kind != CalendarDayKind.upcoming &&
            d.kind != CalendarDayKind.weekend,
      )
      .toList()
      .reversed
      .toList();

  String _format(DateTime? instant) => instant == null
      ? AppStrings.timeMissing
      : _time.format(_clock.toCompany(instant));
}
