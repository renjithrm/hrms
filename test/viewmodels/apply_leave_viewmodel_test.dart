import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/app/app.router.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/exceptions/request_timeout_exception.dart';
import 'package:rebs_hrms/exceptions/validation_exception.dart';
import 'package:rebs_hrms/models/leave_input.dart';
import 'package:rebs_hrms/models/apply_leave_step.dart';
import 'package:rebs_hrms/models/leave_balance.dart';
import 'package:rebs_hrms/models/leave_day_mark.dart';
import 'package:rebs_hrms/models/leave_request.dart';
import 'package:rebs_hrms/models/leave_rule_violation.dart';
import 'package:rebs_hrms/models/leave_status.dart';
import 'package:rebs_hrms/models/leave_type.dart';
import 'package:rebs_hrms/policies/leave_policy.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/ui/views/apply_leave/apply_leave_viewmodel.dart';

import '../helpers/navigation_matchers.dart';
import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

DateTime _nov(int day) => DateTime.utc(2026, 11, day);

final _pending = LeaveRequest(
  id: 'p',
  type: LeaveType.casual,
  startDate: _nov(5),
  endDate: _nov(6),
  reason: 'Family function in Thrissur',
  status: LeaveStatus.pending,
);

void main() {
  group('ApplyLeaveViewModel -', () {
    late MockNavigationService navigation;
    late MockLeaveService leave;
    late MockConnectivityService connectivity;

    ApplyLeaveViewModel pick(int start, int end, {ApplyLeaveViewModel? on}) {
      final model = on ?? ApplyLeaveViewModel();
      model
        ..onDayTapped(_nov(start))
        ..onDayTapped(_nov(end));
      return model;
    }

    setUp(() {
      registerServices();
      locator
        ..unregister<ClockService>()
        ..registerSingleton<ClockService>(
          ClockService(now: () => testNow, timezone: 'Asia/Kolkata'),
        )
        ..unregister<LeavePolicy>()
        ..registerSingleton<LeavePolicy>(LeavePolicy());
      navigation = getAndRegisterNavigationService();
      leave = getAndRegisterLeaveService();
      connectivity = getAndRegisterConnectivityService();
      when(connectivity.isOnline).thenReturn(true);
      const casual = LeaveBalance(
        type: LeaveType.casual,
        entitlement: 10,
        used: 6,
        onHold: 2,
        available: 2,
      );
      const sick = LeaveBalance(
        type: LeaveType.sick,
        entitlement: 6,
        used: 0,
        onHold: 0,
        available: 6,
      );
      when(leave.balances).thenReturn(const [casual, sick]);
      when(leave.balanceFor(LeaveType.casual)).thenReturn(casual);
      when(leave.balanceFor(LeaveType.sick)).thenReturn(sick);
      when(leave.requests).thenReturn([_pending]);
    });

    tearDown(() => locator.reset());

    test('starts on step 1 with casual leave and a hint to pick a start', () {
      final model = ApplyLeaveViewModel();

      expect(model.step, ApplyLeaveStep.dates);
      expect(model.stepLabel, AppStrings.applyStepDates);
      expect(model.type, LeaveType.casual);
      expect(model.availableOf(LeaveType.casual), '2 of 10 left');
      expect(model.dateHint, AppStrings.leavePickStart);
      expect(model.dateError, isNull);
      expect(model.canContinue, isFalse);
    });

    test('first tap sets the start, second the end', () {
      final model = ApplyLeaveViewModel()..onDayTapped(_nov(9));
      expect(model.dateHint, AppStrings.leavePickEnd('9 Nov'));
      expect(model.canContinue, isFalse);

      model.onDayTapped(_nov(10));
      expect(model.rangeStart, _nov(9));
      expect(model.rangeEnd, _nov(10));
    });

    test('a tap before the start, or after a full range, starts again', () {
      final model = ApplyLeaveViewModel()
        ..onDayTapped(_nov(9))
        ..onDayTapped(_nov(3));
      expect(model.rangeStart, _nov(3));
      expect(model.rangeEnd, isNull);

      model
        ..onDayTapped(_nov(4))
        ..onDayTapped(_nov(20));
      expect(model.rangeStart, _nov(20));
      expect(model.rangeEnd, isNull);
    });

    test('days before today cannot be picked', () {
      final model = ApplyLeaveViewModel()
        ..onDayTapped(DateTime.utc(2026, 10, 27));

      expect(model.rangeStart, isNull);
      expect(model.canGoPreviousMonth, isFalse);
    });

    test('a valid range enables Continue and shows the balance after', () {
      final model = pick(9, 10);

      expect(model.dateError, isNull);
      expect(model.dateHint, AppStrings.leaveRangeSummary('9–10 Nov', 2));
      expect(model.balanceAfter, AppStrings.leaveLeftAfter('Casual', 0, 10));
      expect(model.canContinue, isTrue);
    });

    test('overlap with a pending request is shown and blocks Continue', () {
      final model = pick(4, 6);

      expect(
        model.dateError,
        AppStrings.leaveOverlaps(AppStrings.leavePending, '5–6 Nov'),
      );
      expect(model.canContinue, isFalse);
      expect(model.balanceAfter, isNull);
    });

    test('more days than the balance is shown and blocks Continue', () {
      final model = pick(9, 12);

      expect(model.dateError, AppStrings.leaveExceedsBalance(4, 2, 'Casual'));
      expect(model.canContinue, isFalse);
    });

    test('switching type re-checks the range against its balance', () {
      final model = pick(9, 12);

      model.selectType(LeaveType.sick);

      expect(model.dateError, isNull);
      expect(model.canContinue, isTrue);
      expect(model.balanceAfter, AppStrings.leaveLeftAfter('Sick', 2, 6));
    });

    test('each rule has its own message', () {
      final model = ApplyLeaveViewModel();

      expect(
        model.messageFor(const LeaveDatesMissing()),
        AppStrings.leaveDatesMissing,
      );
      expect(
        model.messageFor(const LeaveStartBeforeToday()),
        AppStrings.leaveStartBeforeToday,
      );
      expect(
        model.messageFor(const LeaveEndBeforeStart()),
        AppStrings.leaveEndBeforeStart,
      );
      expect(
        model.messageFor(const LeaveReasonTooShort(4)),
        AppStrings.leaveReasonTooShort(4),
      );
      expect(
        model.messageFor(
          const LeaveExceedsBalance(requested: 3, available: 2),
        ),
        AppStrings.leaveExceedsBalance(3, 2, 'Casual'),
      );
      expect(
        model.messageFor(LeaveOverlaps(_pending)),
        AppStrings.leaveOverlaps(AppStrings.leavePending, '5–6 Nov'),
      );
    });

    test('existing requests are marked on the calendar', () {
      final model = ApplyLeaveViewModel()..nextMonth();

      expect(model.monthLabel, 'November 2026');
      expect(model.dayMarks, {
        _nov(5): LeaveDayMark.pending,
        _nov(6): LeaveDayMark.pending,
      });
      expect(
        model.dayLabelOf(_nov(5)),
        'Thursday 5 November, ${AppStrings.calendarLegendPending}',
      );
      model.previousMonth();
      expect(model.monthLabel, 'October 2026');
    });

    test('Continue goes to step 2; back returns, then leaves', () {
      final model = pick(9, 10)..continueToReview();
      expect(model.step, ApplyLeaveStep.review);
      expect(model.stepLabel, AppStrings.applyStepReview);

      model.onBackPressed();
      expect(model.step, ApplyLeaveStep.dates);
      expect(model.rangeEnd, _nov(10));
      verifyNever(navigation.back());

      model.onBackPressed();
      verify(navigation.back()).called(1);
    });

    test('Continue does nothing while the range is invalid', () {
      final model = pick(4, 6)..continueToReview();

      expect(model.step, ApplyLeaveStep.dates);
    });

    group('step 2 -', () {
      const reason = 'Sister\'s wedding in Kochi';
      final created = LeaveRequest(
        id: 'L-9',
        type: LeaveType.casual,
        startDate: _nov(9),
        endDate: _nov(10),
        reason: reason,
        status: LeaveStatus.pending,
      );

      ApplyLeaveViewModel onReview() => pick(9, 10)..continueToReview();

      test('summarises type, dates, days and balance after', () {
        final model = onReview();

        expect(model.typeLabel, 'Casual');
        expect(model.datesLabel, 'Mon 9 – Tue 10 Nov');
        expect(model.daysLabel, AppStrings.calendarDays(2));
        expect(model.leftAfterLabel, AppStrings.summaryLeftAfter('Casual'));
        expect(model.leftAfterValue, '0 of 10');
      });

      test('reason error appears only after the field is touched', () {
        final model = onReview()..onReasonChanged('Fever');

        expect(model.reasonCountLabel, AppStrings.reasonCount(5));
        expect(model.reasonError, isNull);

        model.onReasonBlurred();
        expect(model.reasonError, AppStrings.leaveReasonTooShort(5));

        model.onReasonChanged(reason);
        expect(model.reasonError, isNull);
        expect(model.isReasonValid, isTrue);
      });

      test('submitting a short reason shows its error and sends nothing',
          () async {
        final model = onReview()..onReasonChanged('Fever');

        await model.submit();

        expect(model.reasonError, AppStrings.leaveReasonTooShort(5));
        verifyNever(leave.submit(any));
      });

      test(
          'success sends the input and replaces the form with the '
          'confirmation', () async {
        when(leave.submit(any)).thenAnswer((_) async => created);
        final model = onReview()..onReasonChanged(reason);

        await model.submit();

        final sent =
            verify(leave.submit(captureAny)).captured.single as LeaveInput;
        expect(sent.startDate, _nov(9));
        expect(sent.endDate, _nov(10));
        expect(sent.reason, reason);
        final arguments = verify(
          navigation.replaceWith<dynamic>(
            Routes.leaveSubmittedView,
            arguments: captureAnyNamed('arguments'),
            id: anyNamed('id'),
            preventDuplicates: true,
            parameters: anyNamed('parameters'),
            transition: anyNamed('transition'),
          ),
        ).captured.single as LeaveSubmittedViewArguments;
        expect(arguments.request, created);
        expect(model.isSubmitting, isFalse);
      });

      test('422 on the dates: banner, dates flagged, reason kept', () async {
        when(leave.submit(any)).thenThrow(
          const ValidationException(
            message: 'Falls in a team blackout period.',
            fieldErrors: {'startDate': 'Falls in a team blackout period.'},
          ),
        );
        final model = onReview()..onReasonChanged(reason);

        await model.submit();

        expect(
          model.serverDatesError,
          AppStrings.leaveNotAcceptedDates('Falls in a team blackout period.'),
        );
        expect(model.areDatesFlagged, isTrue);
        expect(model.reasonError, isNull);
        verifyNeverReplacedWith(navigation, Routes.leaveSubmittedView);

        model
          ..changeDates()
          ..onDayTapped(_nov(16))
          ..onDayTapped(_nov(16));
        expect(model.reason, reason);
        expect(model.areDatesFlagged, isFalse);
      });

      test('422 on the reason lands under the reason field', () async {
        when(leave.submit(any)).thenThrow(
          const ValidationException(
            message: 'Give a reason of at least 10 characters.',
            fieldErrors: {
              'reason': 'Give a reason of at least 10 characters.',
            },
          ),
        );
        final model = onReview()..onReasonChanged(reason);

        await model.submit();

        expect(model.reasonError, 'Give a reason of at least 10 characters.');
        expect(model.serverDatesError, isNull);
      });

      test('offline: submit is blocked and says it needs a connection',
          () async {
        when(connectivity.isOnline).thenReturn(false);
        final model = onReview()..onReasonChanged(reason);

        expect(model.canSubmit, isFalse);
        expect(model.submitLabel, AppStrings.needsConnection);
        await model.submit();

        verifyNever(leave.submit(any));
      });

      test('a timeout warns the request may have been saved', () async {
        when(leave.submit(any)).thenThrow(const RequestTimeoutException());
        final model = onReview()..onReasonChanged(reason);

        await model.submit();

        expect(model.submitError, AppStrings.leaveSubmitTimeout);
        expect(model.canSubmit, isTrue);
      });

      test('other failures show their message', () async {
        when(leave.submit(any)).thenThrow(const OfflineException());
        final model = onReview()..onReasonChanged(reason);

        await model.submit();

        expect(model.submitError, AppStrings.offline);
      });
    });
  });
}
