// lib/ui/views/apply_leave/apply_leave_viewmodel.dart

import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../constants/app_strings.dart';
import '../../../exceptions/request_timeout_exception.dart';
import '../../../exceptions/validation_exception.dart';
import '../../../extensions/date_time_extensions.dart';
import '../../../extensions/error_message_extension.dart';
import '../../../models/apply_leave_step.dart';
import '../../../models/leave_balance.dart';
import '../../../models/leave_day_mark.dart';
import '../../../models/leave_input.dart';
import '../../../models/leave_request.dart';
import '../../../models/leave_rule_violation.dart';
import '../../../models/leave_status.dart';
import '../../../models/leave_type.dart';
import '../../../policies/leave_policy.dart';
import '../../../services/clock_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/leave_service.dart';
import '../../../services/logger_service.dart';

/// Applying for leave. Step 1 (screen J) picks the type and a date range
/// and checks the date rules as the person taps; step 2 (screen K) reviews
/// the choice, takes the reason and submits.
class ApplyLeaveViewModel extends ReactiveViewModel {
  final _navigationService = locator<NavigationService>();
  final _leaveService = locator<LeaveService>();
  final _leavePolicy = locator<LeavePolicy>();
  final _clock = locator<ClockService>();
  final _connectivityService = locator<ConnectivityService>();
  final _logger = locator<LoggerService>();

  final _monthFormat = DateFormat('MMMM yyyy');
  final _dayMonth = DateFormat('d MMM');
  final _day = DateFormat('d');
  final _longDay = DateFormat('EEEE d MMMM');
  final _weekdayDay = DateFormat('EEE d');
  final _weekdayDayMonth = DateFormat('EEE d MMM');

  ApplyLeaveStep _step = ApplyLeaveStep.dates;
  LeaveType _type = LeaveType.casual;
  DateTime? _start;
  DateTime? _end;
  late DateTime _visibleMonth = _todayMonth;
  String _reason = '';
  bool _isReasonTouched = false;
  bool _isSubmitting = false;
  String? _serverDatesError;
  String? _serverReasonError;
  String? _submitError;

  @override
  List<ListenableServiceMixin> get listenableServices => [
        _leaveService,
        _connectivityService,
      ];

  // Navigation

  /// Current step.
  ApplyLeaveStep get step => _step;

  /// "1 of 2" or "2 of 2".
  String get stepLabel => _step == ApplyLeaveStep.dates
      ? AppStrings.applyStepDates
      : AppStrings.applyStepReview;

  /// Back goes to step 1 from step 2, otherwise leaves the flow.
  void onBackPressed() {
    if (_step == ApplyLeaveStep.review) {
      _step = ApplyLeaveStep.dates;
      notifyListeners();
      return;
    }
    _navigationService.back();
  }

  /// Moves to the review step once the dates are valid.
  void continueToReview() {
    if (!canContinue) return;
    _step = ApplyLeaveStep.review;
    notifyListeners();
  }

  // Type

  /// Selected leave type.
  LeaveType get type => _type;

  /// Types to offer, in display order.
  List<LeaveType> get types => LeaveType.values;

  /// Picks a type; the date checks re-run against its balance.
  void selectType(LeaveType type) {
    _type = type;
    _serverDatesError = null;
    notifyListeners();
  }

  /// "6 of 10 left" for [type].
  String availableOf(LeaveType type) {
    final balance = _leaveService.balanceFor(type);
    return AppStrings.leaveTypeAvailable(
      balance?.available ?? 0,
      balance?.entitlement ?? 0,
    );
  }

  // Calendar

  DateTime get _today => _clock.companyToday();

  DateTime get _todayMonth => DateTime.utc(_today.year, _today.month);

  /// The company's today; earlier days can't be picked.
  DateTime get today => _today;

  /// Month shown by the calendar (first day, UTC).
  DateTime get visibleMonth => _visibleMonth;

  /// "November 2026".
  String get monthLabel => _monthFormat.format(_visibleMonth);

  /// The calendar never goes before the current month.
  bool get canGoPreviousMonth => _visibleMonth.isAfter(_todayMonth);

  /// Shows the month before, down to the current month.
  void previousMonth() {
    if (!canGoPreviousMonth) return;
    _visibleMonth = DateTime.utc(_visibleMonth.year, _visibleMonth.month - 1);
    notifyListeners();
  }

  /// Shows the month after.
  void nextMonth() {
    _visibleMonth = DateTime.utc(_visibleMonth.year, _visibleMonth.month + 1);
    notifyListeners();
  }

  /// First chosen day.
  DateTime? get rangeStart => _start;

  /// Last chosen day; null while only the start is chosen.
  DateTime? get rangeEnd => _end;

  /// Pending and approved requests on the visible month, by day.
  Map<DateTime, LeaveDayMark> get dayMarks {
    final marks = <DateTime, LeaveDayMark>{};
    final first = _visibleMonth;
    final last = DateTime.utc(first.year, first.month + 1, 0);
    for (final request in _leaveService.requests) {
      if (!request.blocksOverlap) continue;
      final mark = request.status == LeaveStatus.approved
          ? LeaveDayMark.approved
          : LeaveDayMark.pending;
      var day = request.startDate.isBefore(first) ? first : request.startDate;
      while (!day.isAfter(request.endDate) && !day.isAfter(last)) {
        marks[day] = mark;
        day = day.add(const Duration(days: 1));
      }
    }
    return marks;
  }

  /// Tap on a day: the first tap sets the start, the next sets the end. A
  /// tap before the start, or after a complete range, starts again.
  void onDayTapped(DateTime date) {
    final day = date.dateOnly;
    if (day.isBefore(_today)) return;
    final start = _start;
    _serverDatesError = null;
    if (start == null || _end != null || day.isBefore(start)) {
      _start = day;
      _end = null;
    } else {
      _end = day;
    }
    notifyListeners();
  }

  /// Screen-reader label for a calendar day.
  String dayLabelOf(DateTime date) {
    final mark = dayMarks[date];
    final state = date.isBefore(_today)
        ? AppStrings.leaveDayUnavailable
        : _isInRange(date)
            ? AppStrings.leaveDaySelected
            : switch (mark) {
                LeaveDayMark.pending => AppStrings.calendarLegendPending,
                LeaveDayMark.approved => AppStrings.calendarLegendApproved,
                null => '',
              };
    return AppStrings.leaveDayLabel(_longDay.format(date), state);
  }

  bool _isInRange(DateTime date) {
    final start = _start;
    if (start == null) return false;
    final end = _end ?? start;
    return !date.isBefore(start) && !date.isAfter(end);
  }

  // Validation

  LeaveInput get _input => LeaveInput(
        type: _type,
        startDate: _start,
        endDate: _end,
        reason: _reason,
      );

  /// Date-rule problems with the current choice, overlaps first. Empty
  /// until both ends of the range are chosen; the reason is checked on
  /// step 2.
  List<LeaveRuleViolation> get dateViolations {
    if (_start == null || _end == null) return const [];
    return _leavePolicy
        .validate(
          _input,
          today: _today,
          balances: _leaveService.balances,
          existing: _leaveService.requests,
        )
        .where((v) => v.field == LeaveField.dates)
        .toList()
      // An overlap is the more useful thing to fix first: picking other days
      // may also fix the balance.
      ..sort((a, b) =>
          (b is LeaveOverlaps ? 1 : 0) - (a is LeaveOverlaps ? 1 : 0));
  }

  /// Error under the calendar, or null when the range is fine.
  String? get dateError {
    final violations = dateViolations;
    return violations.isEmpty ? null : messageFor(violations.first);
  }

  /// Guidance or summary under the calendar when there is no error.
  String get dateHint {
    final start = _start;
    final end = _end;
    final days = _input.days;
    if (start == null) return AppStrings.leavePickStart;
    if (end == null || days == null) {
      return AppStrings.leavePickEnd(_dayMonth.format(start));
    }
    return AppStrings.leaveRangeSummary(rangeLabel(start, end), days);
  }

  /// "Casual left after this: 4 of 10", once a valid range is chosen.
  String? get balanceAfter {
    final days = _input.days;
    final balance = _leaveService.balanceFor(_type);
    if (days == null || balance == null || dateError != null) return null;
    return AppStrings.leaveLeftAfter(
      _type.label,
      balance.available - days,
      balance.entitlement,
    );
  }

  /// Whether both dates are chosen and every date rule passes.
  bool get canContinue =>
      _start != null && _end != null && dateViolations.isEmpty;

  /// The message for any leave rule, used here and on step 2.
  String messageFor(LeaveRuleViolation violation) => switch (violation) {
        LeaveDatesMissing() => AppStrings.leaveDatesMissing,
        LeaveStartBeforeToday() => AppStrings.leaveStartBeforeToday,
        LeaveEndBeforeStart() => AppStrings.leaveEndBeforeStart,
        LeaveExceedsBalance(:final requested, :final available) =>
          AppStrings.leaveExceedsBalance(requested, available, _type.label),
        LeaveOverlaps(:final existing) => AppStrings.leaveOverlaps(
            _statusLabel(existing),
            rangeLabel(existing.startDate, existing.endDate),
          ),
        LeaveReasonTooShort(:final count) =>
          AppStrings.leaveReasonTooShort(count),
      };

  String _statusLabel(LeaveRequest request) => switch (request.status) {
        LeaveStatus.pending => AppStrings.leavePending,
        LeaveStatus.approved => AppStrings.leaveApproved,
        LeaveStatus.rejected => AppStrings.leaveRejected,
      };

  /// "5–6 Nov", "14 Oct", or "30 Oct – 2 Nov".
  String rangeLabel(DateTime start, DateTime end) {
    if (start == end) return _dayMonth.format(start);
    if (start.month == end.month && start.year == end.year) {
      return '${_day.format(start)}–${_dayMonth.format(end)}';
    }
    return '${_dayMonth.format(start)} – ${_dayMonth.format(end)}';
  }

  /// Balance for the selected type, for step 2.
  LeaveBalance? get selectedBalance => _leaveService.balanceFor(_type);

  // Step 2: review and reason

  /// "Casual".
  String get typeLabel => _type.label;

  /// "Mon 2 – Tue 3 Nov".
  String get datesLabel {
    final start = _start;
    final end = _end;
    if (start == null || end == null) return '';
    if (start == end) return _weekdayDayMonth.format(start);
    final first = start.month == end.month && start.year == end.year
        ? _weekdayDay.format(start)
        : _weekdayDayMonth.format(start);
    return '$first – ${_weekdayDayMonth.format(end)}';
  }

  /// "2 calendar days".
  String get daysLabel => AppStrings.calendarDays(_input.days ?? 0);

  /// "Casual left after this".
  String get leftAfterLabel => AppStrings.summaryLeftAfter(_type.label);

  /// "4 of 10".
  String get leftAfterValue {
    final balance = _leaveService.balanceFor(_type);
    if (balance == null) return AppStrings.timeMissing;
    return AppStrings.ofTotal(
      balance.available - (_input.days ?? 0),
      balance.entitlement,
    );
  }

  /// Whether the server refused the dates, so the dates row is flagged.
  bool get areDatesFlagged => _serverDatesError != null;

  /// Reason as typed; kept when going back to change dates.
  String get reason => _reason;

  /// Updates the reason as the person types.
  void onReasonChanged(String value) {
    _reason = value;
    _serverReasonError = null;
    notifyListeners();
  }

  /// The field lost focus: from now on its error may show.
  void onReasonBlurred() {
    if (_isReasonTouched) return;
    _isReasonTouched = true;
    notifyListeners();
  }

  /// "33 characters", not counting spaces.
  String get reasonCountLabel => AppStrings.reasonCount(_input.reasonLength);

  /// Whether the reason is long enough.
  bool get isReasonValid => _input.reasonLength >= LeavePolicy.minReasonLength;

  /// Error under the reason, shown only once the field was touched (or a
  /// submit was tried), or the server's message for the field.
  String? get reasonError {
    final server = _serverReasonError;
    if (server != null) return server;
    if (!_isReasonTouched || isReasonValid) return null;
    return messageFor(LeaveReasonTooShort(_input.reasonLength));
  }

  /// Server's refusal of the dates, with what to do; null if none.
  String? get serverDatesError {
    final message = _serverDatesError;
    return message == null ? null : AppStrings.leaveNotAcceptedDates(message);
  }

  /// A failure that isn't about a field (offline, timeout, server error).
  String? get submitError => _submitError;

  /// Whether a submit is in flight.
  bool get isSubmitting => _isSubmitting;

  /// Submitting needs a connection and one request at a time.
  bool get canSubmit => !_isSubmitting && _connectivityService.isOnline;

  /// "Submit request", "Submitting…" or "Needs a connection".
  String get submitLabel {
    if (_isSubmitting) return AppStrings.submitting;
    if (!_connectivityService.isOnline) return AppStrings.needsConnection;
    return AppStrings.submitRequest;
  }

  /// Goes back to step 1, keeping the reason.
  void changeDates() {
    _step = ApplyLeaveStep.dates;
    notifyListeners();
  }

  /// Sends the request. Field errors from the server land on their field;
  /// other failures show above the button. On success the form is replaced
  /// by the confirmation screen.
  Future<void> submit() async {
    if (!canSubmit) return;
    _isReasonTouched = true;
    _submitError = null;
    if (!isReasonValid || !canContinue) {
      notifyListeners();
      return;
    }
    _isSubmitting = true;
    notifyListeners();
    try {
      final created = await _leaveService.submit(_input);
      // Replace the form so back from the confirmation lands on Leave.
      await _navigationService.replaceWithLeaveSubmittedView(
        request: created,
      );
    } on ValidationException catch (e) {
      _applyFieldErrors(e);
    } on RequestTimeoutException catch (e, stackTrace) {
      _logger.error('Submit leave', e, stackTrace);
      _submitError = AppStrings.leaveSubmitTimeout;
    } catch (e, stackTrace) {
      _logger.error('Submit leave', e, stackTrace);
      _submitError = e.userMessage;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _applyFieldErrors(ValidationException error) {
    final fields = error.fieldErrors;
    _serverReasonError = fields['reason'];
    _serverDatesError =
        fields['startDate'] ?? fields['endDate'] ?? fields['type'];
    if (_serverReasonError == null && _serverDatesError == null) {
      _submitError = error.message;
    }
  }
}
