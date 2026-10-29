// lib/ui/views/leave_submitted/leave_submitted_viewmodel.dart

import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../constants/app_strings.dart';
import '../../../models/leave_request.dart';
import '../../../services/leave_service.dart';

/// Screen L: confirms what was sent and shows the new balance, which
/// updates when the background refresh after submitting lands.
class LeaveSubmittedViewModel extends ReactiveViewModel {
  /// Creates the model for the request just sent.
  LeaveSubmittedViewModel(this.request);

  final _navigationService = locator<NavigationService>();
  final _leaveService = locator<LeaveService>();

  final _weekdayDay = DateFormat('EEE d');
  final _weekdayDayMonth = DateFormat('EEE d MMM');

  /// The request the server accepted.
  final LeaveRequest request;

  @override
  List<ListenableServiceMixin> get listenableServices => [_leaveService];

  /// "Casual leave".
  String get typeTitle => AppStrings.leaveTypeTitle(request.type.label);

  /// Status word for the chip; a new request is always pending.
  String get statusLabel => AppStrings.leavePending;

  /// "Mon 9 – Wed 11 Nov".
  String get datesLabel {
    final start = request.startDate;
    final end = request.endDate;
    if (start == end) return _weekdayDayMonth.format(start);
    final first = start.month == end.month && start.year == end.year
        ? _weekdayDay.format(start)
        : _weekdayDayMonth.format(start);
    return '$first – ${_weekdayDayMonth.format(end)}';
  }

  /// "3".
  String get daysLabel => '${request.days}';

  /// "Casual left".
  String get leftLabel => AppStrings.summaryLeft(request.type.label);

  /// "3 of 10 (3 on hold)", or a dash before balances are known.
  String get leftValue {
    final balance = _leaveService.balanceFor(request.type);
    if (balance == null) return AppStrings.timeMissing;
    return AppStrings.balanceWithHold(
      balance.available,
      balance.entitlement,
      balance.onHold,
    );
  }

  /// Returns to the Leave tab, where the request is first in the list.
  void backToLeave() => _navigationService.back();
}
