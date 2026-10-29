import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.bottomsheets.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/models/attendance_day.dart';
import 'package:rebs_hrms/models/calendar_day.dart';
import 'package:rebs_hrms/models/leave_request.dart';
import 'package:rebs_hrms/models/leave_status.dart';
import 'package:rebs_hrms/models/leave_type.dart';
import 'package:rebs_hrms/models/sync_state.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/ui/views/attendance/attendance_viewmodel.dart';

import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

AttendanceDay _day(
  int day, {
  int month = 10,
  bool out = true,
  SyncState state = SyncState.synced,
}) =>
    AttendanceDay(
      workDate:
          '2026-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
      checkInAt: DateTime.utc(2026, month, day, 3, 0),
      checkOutAt: out ? DateTime.utc(2026, month, day, 12, 0) : null,
      checkInState: state,
    );

typedef _Month = ({List<AttendanceDay> days, DateTime? updatedAt});

void main() {
  group('AttendanceViewModel -', () {
    late MockAttendanceService attendance;
    late MockLeaveService leave;
    late MockConnectivityService connectivity;
    final cache = <String, _Month>{};

    setUp(() {
      registerServices();
      locator
        ..unregister<ClockService>()
        ..registerSingleton<ClockService>(
          ClockService(now: () => testNow, timezone: 'Asia/Kolkata'),
        );
      cache.clear();
      attendance = getAndRegisterAttendanceService();
      when(attendance.cachedMonth(any)).thenAnswer(
        (i) async =>
            cache[i.positionalArguments.first as String] ??
            (days: const <AttendanceDay>[], updatedAt: null),
      );
      when(attendance.refreshMonth(any)).thenAnswer((i) async {
        final month = i.positionalArguments.first as String;
        cache[month] = (
          days: cache[month]?.days ?? const <AttendanceDay>[],
          updatedAt: testNow,
        );
      });
      leave = getAndRegisterLeaveService();
      when(leave.requests).thenReturn(const []);
      connectivity = getAndRegisterConnectivityService();
      when(connectivity.isOnline).thenReturn(true);
    });

    tearDown(() => locator.reset());

    test('opens on the current month with today selected', () async {
      cache['2026-10'] = (days: [_day(27), _day(26)], updatedAt: null);
      final model = AttendanceViewModel();
      addTearDown(model.dispose);

      await model.init();

      verify(attendance.refreshMonth('2026-10')).called(1);
      expect(model.monthLabel, 'October 2026');
      expect(model.canGoNext, isFalse);
      expect(model.leadingBlanks, 3); // 1 Oct 2026 is a Thursday.
      expect(model.calendarDays, hasLength(31));
      expect(model.selectedDay?.date, DateTime.utc(2026, 10, 28));
      expect(model.hasError, isFalse);
    });

    test('calendar days get the right kind', () async {
      cache['2026-10'] = (
        days: [_day(28, out: false, state: SyncState.pending), _day(27)],
        updatedAt: testNow,
      );
      when(leave.requests).thenReturn([
        LeaveRequest(
          id: 'l1',
          type: LeaveType.sick,
          startDate: DateTime.utc(2026, 10, 22),
          endDate: DateTime.utc(2026, 10, 23),
          reason: 'Fever, doctor advised rest.',
          status: LeaveStatus.approved,
        ),
      ]);
      final model = AttendanceViewModel();
      addTearDown(model.dispose);
      await model.init();

      CalendarDayKind kindOf(int day) => model.calendarDays[day - 1].kind;
      expect(kindOf(28), CalendarDayKind.waiting);
      expect(kindOf(27), CalendarDayKind.present);
      expect(kindOf(23), CalendarDayKind.leave);
      expect(kindOf(24), CalendarDayKind.weekend);
      expect(kindOf(26), CalendarDayKind.absent);
      expect(kindOf(29), CalendarDayKind.upcoming);
      expect(
        model.statusOf(model.calendarDays[22]),
        AppStrings.dayLeaveDetail('Sick'),
      );
      expect(
        model.semanticsOf(model.calendarDays[26]),
        'Tue, 27 Oct, ${AppStrings.dayPresent}',
      );
    });

    test('summary: days present and the average complete day', () async {
      cache['2026-10'] = (
        days: [
          _day(27),
          AttendanceDay(
            workDate: '2026-10-26',
            checkInAt: DateTime.utc(2026, 10, 26, 3),
            checkOutAt: DateTime.utc(2026, 10, 26, 11),
          ),
          _day(28, out: false),
        ],
        updatedAt: testNow,
      );
      final model = AttendanceViewModel();
      addTearDown(model.dispose);
      await model.init();

      expect(model.presentLabel, AppStrings.summaryDays(3));
      expect(model.averageDayLabel, '8h 30m');
      expect(model.showEmpty, isFalse);
    });

    test('selecting a day shows its times', () async {
      cache['2026-10'] = (days: [_day(27)], updatedAt: testNow);
      final model = AttendanceViewModel();
      addTearDown(model.dispose);
      await model.init();

      model.selectDay(model.calendarDays[26]);

      final selected = model.selectedDay!;
      expect(model.dateLabelOf(selected), 'Tue, 27 Oct');
      expect(model.checkInOf(selected), '08:30');
      expect(model.checkOutOf(selected), '17:30');
      expect(model.workedOf(selected), '9h 0m');
    });

    test('month change loads the previous month and back again', () async {
      cache['2026-09'] = (days: [_day(30, month: 9)], updatedAt: testNow);
      final model = AttendanceViewModel();
      addTearDown(model.dispose);
      await model.init();

      await model.previousMonth();

      expect(model.monthLabel, 'September 2026');
      expect(model.calendarDays, hasLength(30));
      expect(model.presentCount, 1);
      expect(model.selectedDay, isNull);
      expect(model.canGoNext, isTrue);
      verify(attendance.refreshMonth('2026-09')).called(1);

      await model.nextMonth();
      expect(model.monthLabel, 'October 2026');
      await model.nextMonth();
      expect(model.monthLabel, 'October 2026');
    });

    test('offline: a month viewed before comes from the cache', () async {
      cache['2026-09'] = (days: [_day(30, month: 9)], updatedAt: testNow);
      when(attendance.refreshMonth(any)).thenThrow(const OfflineException());
      when(connectivity.isOnline).thenReturn(false);
      final model = AttendanceViewModel();
      addTearDown(model.dispose);
      await model.init();

      await model.previousMonth();

      expect(model.showFullError, isFalse);
      expect(model.presentCount, 1);
      expect(model.bannerMessage, AppStrings.offlineBanner('28 Oct, 09:30'));
    });

    test('offline: a month never viewed shows the full error', () async {
      when(attendance.refreshMonth(any)).thenThrow(const OfflineException());
      final model = AttendanceViewModel();
      addTearDown(model.dispose);
      await model.init();

      expect(model.showFullError, isTrue);
      expect(model.errorMessage, AppStrings.offline);
      expect(model.showLoading, isFalse);
    });

    test('empty month says so', () async {
      final model = AttendanceViewModel();
      addTearDown(model.dispose);
      await model.init();
      await model.previousMonth();

      expect(model.showEmpty, isTrue);
      expect(model.emptyTitle, AppStrings.emptyMonthTitle('September'));
      expect(model.averageDayLabel, AppStrings.timeMissing);
    });

    test('list view lists past working days, newest first', () async {
      cache['2026-10'] = (days: [_day(27)], updatedAt: testNow);
      final model = AttendanceViewModel();
      addTearDown(model.dispose);
      await model.init();

      model.toggleListView();

      expect(model.isListView, isTrue);
      expect(model.viewToggleLabel, AppStrings.showAsCalendar);
      expect(model.listDays.first.date, DateTime.utc(2026, 10, 28));
      expect(
        model.listDays.map((d) => d.kind),
        isNot(contains(CalendarDayKind.weekend)),
      );
      expect(model.listDays.last.date, DateTime.utc(2026, 10, 1));
    });

    test('the pill opens the sync sheet', () async {
      final sheets = getAndRegisterBottomSheetService();

      await AttendanceViewModel().openSyncQueue();

      verify(
        sheets.showCustomSheet(
          variant: BottomSheetType.syncQueue,
          isScrollControlled: true,
        ),
      ).called(1);
    });
  });
}
