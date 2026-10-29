import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/models/leave_balance.dart';
import 'package:rebs_hrms/models/leave_request.dart';
import 'package:rebs_hrms/models/leave_status.dart';
import 'package:rebs_hrms/models/leave_type.dart';
import 'package:rebs_hrms/ui/views/leave_submitted/leave_submitted_viewmodel.dart';

import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

final _request = LeaveRequest(
  id: 'L-9',
  type: LeaveType.casual,
  startDate: DateTime.utc(2026, 11, 9),
  endDate: DateTime.utc(2026, 11, 11),
  reason: 'Sister\'s wedding in Kochi',
  status: LeaveStatus.pending,
);

void main() {
  group('LeaveSubmittedViewModel -', () {
    late MockLeaveService leave;

    setUp(() {
      registerServices();
      leave = getAndRegisterLeaveService();
    });

    tearDown(() => locator.reset());

    test('summarises the request that was sent', () {
      final model = LeaveSubmittedViewModel(_request);

      expect(model.typeTitle, AppStrings.leaveTypeTitle('Casual'));
      expect(model.statusLabel, AppStrings.leavePending);
      expect(model.datesLabel, 'Mon 9 – Wed 11 Nov');
      expect(model.daysLabel, '3');
      expect(model.leftLabel, AppStrings.summaryLeft('Casual'));
    });

    test('shows the new balance with days on hold', () {
      when(leave.balanceFor(LeaveType.casual)).thenReturn(
        const LeaveBalance(
          type: LeaveType.casual,
          entitlement: 10,
          used: 4,
          onHold: 3,
          available: 3,
        ),
      );

      expect(
        LeaveSubmittedViewModel(_request).leftValue,
        AppStrings.balanceWithHold(3, 10, 3),
      );
    });

    test('before balances are known it shows a dash', () {
      expect(
        LeaveSubmittedViewModel(_request).leftValue,
        AppStrings.timeMissing,
      );
    });

    test('Back to leave returns to the Leave tab', () {
      final navigation = getAndRegisterNavigationService();

      LeaveSubmittedViewModel(_request).backToLeave();

      verify(navigation.back()).called(1);
    });
  });
}
