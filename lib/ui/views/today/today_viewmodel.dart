// lib/ui/views/today/today_viewmodel.dart

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.bottomsheets.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../app/config/app_config.dart';
import '../../../constants/app_strings.dart';
import '../../../extensions/date_time_extensions.dart';
import '../../../extensions/error_message_extension.dart';
import '../../../models/attendance_day.dart';
import '../../../models/attendance_outcome.dart';
import '../../../models/attendance_result.dart';
import '../../../models/attendance_rule_violation.dart';
import '../../../models/geofence_result.dart';
import '../../../models/leave_balance.dart';
import '../../../models/location_check.dart';
import '../../../models/location_failure.dart';
import '../../../models/location_reading.dart';
import '../../../models/office_location.dart';
import '../../../models/sync_summary.dart';
import '../../../models/today_status.dart';
import '../../../policies/geofence_policy.dart';
import '../../../services/app_lifecycle_service.dart';
import '../../../services/attendance_service.dart';
import '../../../services/clock_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/dev_settings_service.dart';
import '../../../services/employee_service.dart';
import '../../../services/leave_service.dart';
import '../../../services/location_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/sync_service.dart';

/// Today tab: who the person is, today's status, leave left and the last
/// five days. Shows cached data first and refreshes in the background.
class TodayViewModel extends ReactiveViewModel {
  final _navigationService = locator<NavigationService>();
  final _devSettingsService = locator<DevSettingsService>();
  final _employeeService = locator<EmployeeService>();
  final _attendanceService = locator<AttendanceService>();
  final _leaveService = locator<LeaveService>();
  final _connectivityService = locator<ConnectivityService>();
  final _clock = locator<ClockService>();
  final _logger = locator<LoggerService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _locationService = locator<LocationService>();
  final _geofencePolicy = locator<GeofencePolicy>();
  final _appLifecycleService = locator<AppLifecycleService>();
  final _syncService = locator<SyncService>();

  /// How often the location is re-read while the screen is open.
  static const Duration locationRecheckInterval = Duration(seconds: 30);

  /// How often the elapsed time on the shift ring updates.
  static const Duration elapsedTick = Duration(seconds: 1);

  /// Shift length assumed before the employee's shift is known.
  static const Duration defaultShift = Duration(hours: 9);

  LocationCheck _location = const LocationChecking();
  bool _isReadingLocation = false;
  bool _isSubmitting = false;
  String? _actionMessage;
  Timer? _locationTimer;
  Timer? _elapsedTimer;
  StreamSubscription<void>? _resumeSubscription;

  final _time = DateFormat('HH:mm');
  final _longDate = DateFormat('EEEE, d MMM');
  final _weekday = DateFormat('E');

  @override
  List<ListenableServiceMixin> get listenableServices => [
        _employeeService,
        _attendanceService,
        _leaveService,
        _connectivityService,
        _syncService,
      ];

  /// Loads the cache, starts watching the location, then refreshes from
  /// the API.
  Future<void> init() async {
    try {
      await _attendanceService.loadCached();
      await _leaveService.loadCached();
    } catch (e, stackTrace) {
      _logger.error('Today cache', e, stackTrace);
    }
    _watchLocation();
    _elapsedTimer ??= Timer.periodic(elapsedTick, (_) {
      if (status is TodayCheckedIn) notifyListeners();
    });
    await refresh();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _locationTimer?.cancel();
    _resumeSubscription?.cancel();
    super.dispose();
  }

  /// Sends anything waiting, then refreshes attendance and leave. Used by
  /// init and pull-to-refresh.
  Future<void> refresh() async {
    clearErrors();
    setBusy(true);
    try {
      await _syncService.syncNow();
      await Future.wait([
        _attendanceService.refresh(),
        _leaveService.refresh(),
      ]);
    } catch (e, stackTrace) {
      _logger.error('Today refresh', e, stackTrace);
      setError(e);
    } finally {
      setBusy(false);
    }
  }

  // Screen state

  /// Whether anything has been downloaded before, so cached content exists.
  bool get hasCache => _attendanceService.hasCache;

  /// First launch of this screen with nothing cached: show the skeleton.
  bool get showSkeleton => isBusy && !hasCache;

  /// Refresh failed with nothing cached: show the full error state.
  bool get showFullError => hasError && !hasCache;

  /// Message for the full error state.
  String get errorMessage {
    final Object? error = modelError;
    return error?.userMessage ?? AppStrings.unexpectedError;
  }

  /// Banner above cached content, or null when the data is fresh.
  String? get bannerMessage {
    final updated = _attendanceService.lastUpdated;
    if (!hasCache || updated == null) return null;
    final time = _formatTime(updated);
    if (!_connectivityService.isOnline) return AppStrings.offlineBanner(time);
    if (hasError) return AppStrings.refreshFailedBanner(time);
    return null;
  }

  /// Whether the banner reports a failure rather than being offline.
  bool get isBannerAnError => hasError && _connectivityService.isOnline;

  // Header

  /// Employee name.
  String get name => _employeeService.employee?.name ?? '';

  /// Avatar initials.
  String get initials => _employeeService.employee?.initials ?? '';

  /// "EMP-1042 · Engineering".
  String get idAndDepartment {
    final employee = _employeeService.employee;
    if (employee == null) return '';
    return '${employee.id} · ${employee.department}';
  }

  /// Greeting for the company's time of day.
  String get greeting {
    final hour = _clock.companyNow().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
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

  // Today card

  /// "Wednesday, 28 Oct" in company time.
  String get dateLabel => _longDate.format(_clock.companyNow());

  /// "Shift 09:00 – 18:00 · IST".
  String get shiftLabel {
    final shift = _employeeService.employee?.shift;
    if (shift == null) return '';
    return AppStrings.shiftLine(
      shift.startLabel,
      shift.endLabel,
      _clock.timezoneAbbreviation,
    );
  }

  /// Today's status.
  TodayStatus get status => TodayStatus.from(_attendanceService.today);

  /// Check-in time today, or a dash.
  String get checkInLabel =>
      _formatOptional(_attendanceService.today?.checkInAt);

  /// Check-out time today, or a dash.
  String get checkOutLabel =>
      _formatOptional(_attendanceService.today?.checkOutAt);

  /// Time since check-in, "3:12:45". Empty unless checked in.
  String get elapsedLabel {
    final elapsed = _elapsed;
    if (elapsed == null) return '';
    return AppStrings.elapsed(
      elapsed.inHours,
      elapsed.inMinutes % 60,
      elapsed.inSeconds % 60,
    );
  }

  /// Share of the shift worked, 0 to 1, in whole minutes so the ring moves
  /// once a minute.
  double get shiftProgress {
    final elapsed = _elapsed;
    if (elapsed == null) return 0;
    return (elapsed.inMinutes / _shiftLength.inMinutes).clamp(0.0, 1.0);
  }

  /// "of 9h shift".
  String get ringCaption => AppStrings.ringCaption(_shiftLength.inHours);

  /// "Worked 9h 11m today", once checked out.
  String get workedTodayLabel {
    final today = _attendanceService.today;
    if (today == null || today.worked == null) return '';
    return AppStrings.workedToday(workedOf(today));
  }

  Duration? get _elapsed {
    final checkIn = _attendanceService.today?.checkInAt;
    if (status is! TodayCheckedIn || checkIn == null) return null;
    final elapsed = _clock.nowUtc().difference(checkIn);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  Duration get _shiftLength {
    final length = _employeeService.employee?.shift.length;
    return length == null || length <= Duration.zero ? defaultShift : length;
  }

  // Slider

  /// Whether the slider is shown (until the day is complete).
  bool get showSlider => status is! TodayCheckedOut;

  /// Whether sliding is allowed right now: inside the office, not busy.
  bool get canSlide => _location is LocationInside && !_isSubmitting;

  /// Whether a check-in or check-out is being recorded.
  bool get isSubmitting => _isSubmitting;

  /// "Slide to check in" or "Slide to check out".
  String get slideLabel => status is TodayCheckedIn
      ? AppStrings.slideToCheckOut
      : AppStrings.slideToCheckIn;

  /// Why the last attempt didn't go through, or null.
  String? get actionMessage => _actionMessage;

  /// Records a check-in or check-out, depending on today's status. Returns
  /// whether it was recorded, so the slider shows a tick or springs back.
  Future<bool> onSlideConfirmed() async {
    final current = status;
    if (current is TodayCheckedOut || _isSubmitting) return false;
    _isSubmitting = true;
    _actionMessage = null;
    notifyListeners();
    try {
      final outcome = current is TodayCheckedIn
          ? await _attendanceService.checkOut(office)
          : await _attendanceService.checkIn(office);
      return _handleOutcome(outcome);
    } catch (e, stackTrace) {
      _logger.error('Check in/out', e, stackTrace);
      _actionMessage = e.userMessage;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// The person tried the locked slider: read the location again.
  void onLockedSlideTap() {
    if (_location is LocationChecking) return;
    unawaited(onLocationAction());
  }

  bool _handleOutcome(AttendanceOutcome outcome) {
    switch (outcome) {
      case AttendanceRecorded(:final event, :final isSynced):
        unawaited(
          _bottomSheetService.showCustomSheet(
            variant: BottomSheetType.attendanceResult,
            data: AttendanceResult(
              type: event.type,
              timeLabel: _formatTime(event.occurredAt),
              placeLabel: office.name,
              isSynced: isSynced,
            ),
            isScrollControlled: true,
          ),
        );
        return true;
      case AttendanceRefused(:final violation):
        _actionMessage = switch (violation) {
          AttendanceRuleViolation.alreadyCheckedIn =>
            AppStrings.alreadyCheckedIn,
          AttendanceRuleViolation.checkOutBeforeCheckIn =>
            AppStrings.checkOutBeforeCheckIn,
          AttendanceRuleViolation.alreadyCheckedOut =>
            AppStrings.alreadyCheckedOut,
        };
        return false;
      case AttendanceNotAtOffice(:final result):
        switch (result) {
          case GeofenceOutside(:final distanceMetres, :final radiusMetres):
            _location = LocationOutside(
              distanceMetres: distanceMetres,
              radiusMetres: radiusMetres,
            );
            _actionMessage = AppStrings.outsideOffice(
              distanceMetres.round(),
              radiusMetres.round(),
            );
          case GeofenceInaccurate(:final accuracyMetres):
            _location = LocationImprecise(accuracyMetres);
            _actionMessage =
                AppStrings.inaccurateLocation(accuracyMetres.round());
          case GeofenceInside():
            break;
        }
        return false;
      case AttendanceLocationFailed(:final reason):
        _location = LocationBlocked(reason);
        unawaited(openLocationHelp());
        return false;
    }
  }

  // Leave card

  /// Leave balances in display order.
  List<LeaveBalance> get balances => _leaveService.balances;

  // Recent list

  /// Latest days with attendance, newest first.
  List<AttendanceDay> get recentDays => _attendanceService.recent;

  /// Day of the month, for the date tile.
  String dayNumberOf(AttendanceDay day) =>
      parseIsoDate(day.workDate).day.toString();

  /// Short weekday, for the date tile.
  String weekdayOf(AttendanceDay day) =>
      _weekday.format(parseIsoDate(day.workDate));

  /// "08:41 – 17:52".
  String timeRangeOf(AttendanceDay day) =>
      '${_formatOptional(day.checkInAt)} – ${_formatOptional(day.checkOutAt)}';

  /// "9h 11m", or empty while the day is open.
  String workedOf(AttendanceDay day) {
    final worked = day.worked;
    if (worked == null) return '';
    return AppStrings.hoursMinutes(worked.inHours, worked.inMinutes % 60);
  }

  // Location

  /// Whether attendance is possible from where the person is.
  LocationCheck get location => _location;

  /// The location tile shows until the day is complete.
  bool get showLocation => status is! TodayCheckedOut;

  /// Whether the small map is shown (outside the office area).
  bool get showMap => _location is LocationOutside;

  /// Office used for the geofence: the server's, or the build default.
  OfficeLocation get office =>
      _employeeService.employee?.office ??
      OfficeLocation(
        name: AppStrings.mapOfficeLabel,
        latitude: AppConfig.current.officeLatitude,
        longitude: AppConfig.current.officeLongitude,
        radiusMetres: AppConfig.current.officeRadiusMetres,
      );

  /// Main line of the location tile.
  String get locationTitle => switch (_location) {
        LocationChecking() => AppStrings.locationChecking,
        LocationInside() => AppStrings.locationInside,
        LocationOutside(:final distanceMetres) =>
          AppStrings.locationOutside(distanceMetres.round()),
        LocationImprecise() => AppStrings.locationImprecise,
        LocationBlocked(:final reason) => switch (reason) {
            LocationFailure.denied => AppStrings.locationDenied,
            LocationFailure.deniedForever => AppStrings.locationBlocked,
            LocationFailure.serviceOff => AppStrings.locationServiceOff,
            LocationFailure.unavailable => AppStrings.locationUnavailable,
          },
      };

  /// Second line of the location tile.
  String get locationDetail => switch (_location) {
        LocationChecking() => AppStrings.locationCheckingDetail,
        LocationInside(:final distanceMetres, :final accuracyMetres) =>
          AppStrings.locationInsideDetail(
            distanceMetres.round(),
            office.name,
            accuracyMetres.round(),
          ),
        LocationOutside(:final radiusMetres) =>
          AppStrings.locationOutsideDetail(radiusMetres.round(), office.name),
        LocationImprecise(:final accuracyMetres) =>
          AppStrings.locationImpreciseDetail(accuracyMetres.round()),
        LocationBlocked(:final reason) => switch (reason) {
            LocationFailure.denied => AppStrings.locationDeniedDetail,
            LocationFailure.deniedForever => AppStrings.locationBlockedDetail,
            LocationFailure.serviceOff => AppStrings.locationServiceOffDetail,
            LocationFailure.unavailable => AppStrings.locationUnavailableDetail,
          },
      };

  /// Label of the tile's action button, or null when none is needed.
  String? get locationActionLabel => switch (_location) {
        LocationChecking() || LocationInside() => null,
        LocationOutside() ||
        LocationImprecise() =>
          AppStrings.actionUpdateLocation,
        LocationBlocked(:final reason) => switch (reason) {
            LocationFailure.denied => AppStrings.actionAllowLocation,
            LocationFailure.deniedForever ||
            LocationFailure.serviceOff =>
              AppStrings.actionFix,
            LocationFailure.unavailable => AppStrings.actionUpdateLocation,
          },
      };

  /// Runs the tile's action: re-read, ask for permission, or explain how to
  /// fix the setting.
  Future<void> onLocationAction() async {
    final current = _location;
    if (current is LocationBlocked &&
        current.reason != LocationFailure.unavailable) {
      if (current.reason == LocationFailure.denied) {
        await checkLocation(askPermission: true);
        if (_location is! LocationBlocked) return;
      }
      await openLocationHelp();
      return;
    }
    await checkLocation();
  }

  /// Opens the sheet explaining how to turn location back on.
  Future<void> openLocationHelp() async {
    final current = _location;
    if (current is! LocationBlocked) return;
    final response = await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.locationPermission,
      data: current.reason,
      isScrollControlled: true,
    );
    if (response?.confirmed ?? false) await checkLocation(askPermission: true);
  }

  /// Reads the location and updates the tile. Skipped once the day is
  /// complete or while a read is already running.
  Future<void> checkLocation({bool askPermission = false}) async {
    if (!showLocation || _isReadingLocation) return;
    _isReadingLocation = true;
    _location = const LocationChecking();
    notifyListeners();
    try {
      final reading =
          await _locationService.read(office, askPermission: askPermission);
      _location = _toCheck(reading);
    } catch (e, stackTrace) {
      _logger.error('Location read', e, stackTrace);
      _location = const LocationBlocked(LocationFailure.unavailable);
    } finally {
      _isReadingLocation = false;
      notifyListeners();
    }
  }

  void _watchLocation() {
    unawaited(checkLocation(askPermission: true));
    _locationTimer ??= Timer.periodic(
      locationRecheckInterval,
      (_) => checkLocation(),
    );
    _resumeSubscription ??=
        _appLifecycleService.resumed$.listen((_) => checkLocation());
  }

  LocationCheck _toCheck(LocationReading reading) => switch (reading) {
        LocationUnreadable(:final reason) => LocationBlocked(reason),
        LocationFix(:final position) => switch (
              _geofencePolicy.check(position, office)) {
            GeofenceInside(:final distanceMetres) => LocationInside(
                distanceMetres: distanceMetres,
                accuracyMetres: position.accuracyMetres,
              ),
            GeofenceOutside(:final distanceMetres, :final radiusMetres) =>
              LocationOutside(
                distanceMetres: distanceMetres,
                radiusMetres: radiusMetres,
              ),
            GeofenceInaccurate(:final accuracyMetres) =>
              LocationImprecise(accuracyMetres),
          },
      };

  // Actions

  /// Whether developer settings can be opened (debug builds only).
  bool get canOpenDevSettings => _devSettingsService.isAvailable;

  /// Opens developer settings in debug builds; does nothing otherwise.
  Future<void> openDevSettings() async {
    if (!canOpenDevSettings) return;
    await _navigationService.navigateToDevSettingsView();
  }

  String _formatOptional(DateTime? instant) =>
      instant == null ? AppStrings.timeMissing : _formatTime(instant);

  String _formatTime(DateTime instant) =>
      _time.format(_clock.toCompany(instant));
}
