import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/app/app.router.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/exceptions/server_exception.dart';
import 'package:rebs_hrms/models/attendance_day.dart';
import 'package:rebs_hrms/models/attendance_event.dart';
import 'package:rebs_hrms/models/attendance_event_type.dart';
import 'package:rebs_hrms/models/attendance_outcome.dart';
import 'package:rebs_hrms/models/attendance_result.dart';
import 'package:rebs_hrms/models/attendance_rule_violation.dart';
import 'package:rebs_hrms/models/geofence_result.dart';
import 'package:rebs_hrms/models/sync_state.dart';
import 'package:rebs_hrms/models/sync_summary.dart';
import 'package:rebs_hrms/models/today_status.dart';
import 'package:rebs_hrms/app/app.bottomsheets.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/location_check.dart';
import 'package:rebs_hrms/models/location_failure.dart';
import 'package:rebs_hrms/models/location_reading.dart';
import 'package:rebs_hrms/policies/geofence_policy.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/ui/views/today/today_viewmodel.dart';

import '../helpers/fixtures.dart';
import '../helpers/navigation_matchers.dart';
import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

final _checkedInToday = AttendanceDay(
  workDate: '2026-10-28',
  checkInAt: DateTime.utc(2026, 10, 28, 3, 2),
  checkInState: SyncState.pending,
);

void main() {
  group('TodayViewModel -', () {
    late MockAttendanceService attendance;
    late MockLeaveService leave;
    late MockConnectivityService connectivity;
    late MockLocationService location;
    late MockSyncService sync;

    void positionNorthOfOffice(double metres) =>
        when(location.read(any, askPermission: anyNamed('askPermission')))
            .thenAnswer(
          (_) async => LocationFix(
            GeoPosition(
              latitude: testEmployee.office.latitude + metres / 111194.93,
              longitude: testEmployee.office.longitude,
              accuracyMetres: 12,
            ),
          ),
        );

    void locationFails(LocationFailure reason) =>
        when(location.read(any, askPermission: anyNamed('askPermission')))
            .thenAnswer((_) async => LocationUnreadable(reason));

    setUp(() {
      registerServices();
      locator
        ..unregister<ClockService>()
        ..registerSingleton<ClockService>(
          ClockService(now: () => testNow, timezone: 'Asia/Kolkata'),
        );
      final employees = getAndRegisterEmployeeService();
      when(employees.employee).thenReturn(testEmployee);
      attendance = getAndRegisterAttendanceService();
      leave = getAndRegisterLeaveService();
      connectivity = getAndRegisterConnectivityService();
      when(connectivity.isOnline).thenReturn(true);
      when(attendance.recent).thenReturn(const []);
      when(attendance.loadCached()).thenAnswer((_) async {});
      when(leave.loadCached()).thenAnswer((_) async {});
      when(attendance.refresh()).thenAnswer((_) async {});
      when(leave.refresh()).thenAnswer((_) async {});
      locator
        ..unregister<GeofencePolicy>()
        ..registerSingleton<GeofencePolicy>(GeofencePolicy());
      final lifecycle = getAndRegisterAppLifecycleService();
      when(lifecycle.resumed$).thenAnswer((_) => const Stream.empty());
      location = getAndRegisterLocationService();
      positionNorthOfOffice(40);
      sync = getAndRegisterSyncService();
      when(sync.summary).thenReturn(const SyncAllSynced());
      when(sync.syncNow(ignoreBackoff: anyNamed('ignoreBackoff')))
          .thenAnswer((_) async {});
    });

    tearDown(() => locator.reset());

    test('loads cache then refreshes without errors', () async {
      when(attendance.hasCache).thenReturn(true);
      when(attendance.lastUpdated).thenReturn(testNow);

      final model = TodayViewModel();
      addTearDown(model.dispose);
      await model.init();

      verify(attendance.loadCached()).called(1);
      verify(attendance.refresh()).called(1);
      expect(model.hasError, isFalse);
      expect(model.bannerMessage, isNull);
      expect(model.syncSummary, isA<SyncAllSynced>());
    });

    test('a failed refresh over cached data shows a banner, not a full error',
        () async {
      when(attendance.hasCache).thenReturn(true);
      when(attendance.lastUpdated).thenReturn(testNow);
      when(attendance.refresh()).thenThrow(const ServerException(500));

      final model = TodayViewModel();
      addTearDown(model.dispose);
      await model.init();

      expect(model.showFullError, isFalse);
      expect(model.bannerMessage, AppStrings.refreshFailedBanner('09:30'));
      expect(model.isBannerAnError, isTrue);
    });

    test('a failed first load with nothing cached shows the full error',
        () async {
      when(attendance.hasCache).thenReturn(false);
      when(attendance.refresh()).thenThrow(const OfflineException());

      final model = TodayViewModel();
      addTearDown(model.dispose);
      await model.init();

      expect(model.showFullError, isTrue);
      expect(model.isBusy, isFalse);
      expect(model.errorMessage, AppStrings.offline);
    });

    test('offline with cached data says so and shows the offline pill', () {
      when(connectivity.isOnline).thenReturn(false);
      when(attendance.hasCache).thenReturn(true);
      when(attendance.lastUpdated).thenReturn(testNow);

      final model = TodayViewModel();

      expect(model.bannerMessage, AppStrings.offlineBanner('09:30'));
    });

    test('a check-in waiting to sync drives status and the pill', () {
      when(attendance.today).thenReturn(_checkedInToday);
      when(attendance.recent).thenReturn([_checkedInToday]);

      final model = TodayViewModel();

      expect(model.status, isA<TodayCheckedIn>());
      expect(model.checkInLabel, '08:32');
      expect(model.checkOutLabel, AppStrings.timeMissing);
    });

    test('pull to refresh sends waiting entries first', () async {
      final model = TodayViewModel();
      await model.refresh();

      verifyInOrder([sync.syncNow(), attendance.refresh()]);
    });

    test('the pill shows the sync state and opens the sync sheet', () async {
      when(sync.summary).thenReturn(const SyncWaiting(1));
      final sheets = getAndRegisterBottomSheetService();
      final model = TodayViewModel();

      expect((model.syncSummary as SyncWaiting).count, 1);
      await model.openSyncQueue();

      verify(
        sheets.showCustomSheet(
          variant: BottomSheetType.syncQueue,
          isScrollControlled: true,
        ),
      ).called(1);
    });

    test('formats header and recent rows in company time', () {
      final day = AttendanceDay(
        workDate: '2026-10-27',
        checkInAt: DateTime.utc(2026, 10, 27, 3, 11),
        checkOutAt: DateTime.utc(2026, 10, 27, 12, 22),
      );
      final model = TodayViewModel();

      expect(model.idAndDepartment, 'EMP-1042 · Engineering');
      expect(model.initials, 'AN');
      expect(model.greeting, AppStrings.goodMorning);
      expect(model.dateLabel, 'Wednesday, 28 Oct');
      expect(model.shiftLabel, AppStrings.shiftLine('09:00', '18:00', 'IST'));
      expect(model.timeRangeOf(day), '08:41 – 17:52');
      expect(model.workedOf(day), '9h 11m');
      expect(model.weekdayOf(day), 'Tue');
    });

    test('long-pressing the avatar opens developer settings', () async {
      final navigation = getAndRegisterNavigationService();
      final devSettings = getAndRegisterDevSettingsService();
      when(devSettings.isAvailable).thenReturn(true);

      await TodayViewModel().openDevSettings();

      verifyNavigatedTo(navigation, Routes.devSettingsView);
    });
    group('location -', () {
      test('init reads the location, asking for permission once', () async {
        final model = TodayViewModel();
        addTearDown(model.dispose);
        await model.init();

        verify(location.read(any, askPermission: true)).called(1);
        expect(model.location, isA<LocationInside>());
      });

      test('inside the area: no action needed', () async {
        final model = TodayViewModel();
        await model.checkLocation();

        expect(model.locationTitle, AppStrings.locationInside);
        expect(
          model.locationDetail,
          AppStrings.locationInsideDetail(40, 'Infopark Phase 1', 12),
        );
        expect(model.locationActionLabel, isNull);
        expect(model.showMap, isFalse);
      });

      test('outside the area: distance, map and a way to re-check', () async {
        positionNorthOfOffice(850);
        final model = TodayViewModel();
        await model.checkLocation();

        expect(model.location, isA<LocationOutside>());
        expect(model.locationTitle, AppStrings.locationOutside(850));
        expect(model.showMap, isTrue);
        expect(model.locationActionLabel, AppStrings.actionUpdateLocation);
      });

      test('permanently denied: the action opens the help sheet', () async {
        locationFails(LocationFailure.deniedForever);
        final sheets = getAndRegisterBottomSheetService();
        final model = TodayViewModel();
        await model.checkLocation();

        expect(model.locationTitle, AppStrings.locationBlocked);
        expect(model.locationActionLabel, AppStrings.actionFix);
        await model.onLocationAction();

        verify(
          sheets.showCustomSheet(
            variant: BottomSheetType.locationPermission,
            data: LocationFailure.deniedForever,
            isScrollControlled: true,
          ),
        ).called(1);
      });

      test('denied: the action asks for permission again first', () async {
        locationFails(LocationFailure.denied);
        final model = TodayViewModel();
        await model.checkLocation();
        positionNorthOfOffice(10);

        await model.onLocationAction();

        verify(location.read(any, askPermission: true)).called(1);
        expect(model.location, isA<LocationInside>());
      });

      test('no fix: tile says so and offers a retry', () async {
        locationFails(LocationFailure.unavailable);
        final model = TodayViewModel();
        await model.checkLocation();

        expect(model.locationTitle, AppStrings.locationUnavailable);
        expect(model.locationActionLabel, AppStrings.actionUpdateLocation);
      });

      test('a finished day does not read the location', () async {
        when(attendance.today).thenReturn(
          AttendanceDay(
            workDate: '2026-10-28',
            checkInAt: DateTime.utc(2026, 10, 28, 3),
            checkOutAt: DateTime.utc(2026, 10, 28, 12),
          ),
        );
        final model = TodayViewModel();
        await model.checkLocation();

        expect(model.showLocation, isFalse);
        verifyNever(
          location.read(any, askPermission: anyNamed('askPermission')),
        );
      });
    });
    group('slider -', () {
      AttendanceEvent recorded(AttendanceEventType type) => AttendanceEvent(
            eventId: 'e1',
            type: type,
            workDate: '2026-10-28',
            occurredAt: DateTime.utc(2026, 10, 28, 3, 32),
            position: const GeoPosition(
              latitude: 10.0159,
              longitude: 76.3419,
              accuracyMetres: 12,
            ),
          );

      test('locked until the location is inside the office', () async {
        positionNorthOfOffice(850);
        final model = TodayViewModel();
        expect(model.canSlide, isFalse);

        await model.checkLocation();
        expect(model.canSlide, isFalse);

        positionNorthOfOffice(40);
        await model.checkLocation();
        expect(model.canSlide, isTrue);
        expect(model.slideLabel, AppStrings.slideToCheckIn);
      });

      test('slide to check in shows the result sheet', () async {
        final sheets = getAndRegisterBottomSheetService();
        when(attendance.checkIn(any)).thenAnswer(
          (_) async => AttendanceRecorded(
            recorded(AttendanceEventType.checkIn),
            isSynced: true,
          ),
        );
        final model = TodayViewModel();

        final isRecorded = await model.onSlideConfirmed();

        expect(isRecorded, isTrue);
        expect(model.actionMessage, isNull);
        expect(model.isSubmitting, isFalse);
        final data = verify(
          sheets.showCustomSheet(
            variant: BottomSheetType.attendanceResult,
            data: captureAnyNamed('data'),
            isScrollControlled: true,
          ),
        ).captured.single as AttendanceResult;
        expect(data.type, AttendanceEventType.checkIn);
        expect(data.timeLabel, '09:02');
        expect(data.placeLabel, 'Infopark Phase 1');
        expect(data.isSynced, isTrue);
      });

      test('when checked in, the slider checks out', () async {
        when(attendance.today).thenReturn(_checkedInToday);
        when(attendance.checkOut(any)).thenAnswer(
          (_) async => AttendanceRecorded(
            recorded(AttendanceEventType.checkOut),
            isSynced: false,
          ),
        );
        final model = TodayViewModel();

        expect(model.slideLabel, AppStrings.slideToCheckOut);
        expect(await model.onSlideConfirmed(), isTrue);
        verify(attendance.checkOut(testEmployee.office)).called(1);
        verifyNever(attendance.checkIn(any));
      });

      test('a rule violation is shown and nothing is recorded', () async {
        final sheets = getAndRegisterBottomSheetService();
        when(attendance.checkIn(any)).thenAnswer(
          (_) async =>
              const AttendanceRefused(AttendanceRuleViolation.alreadyCheckedIn),
        );
        final model = TodayViewModel();

        expect(await model.onSlideConfirmed(), isFalse);
        expect(model.actionMessage, AppStrings.alreadyCheckedIn);
        verifyNever(
          sheets.showCustomSheet(
            variant: BottomSheetType.attendanceResult,
            data: anyNamed('data'),
            isScrollControlled: anyNamed('isScrollControlled'),
          ),
        );
      });

      test('outside on the fresh read: tile and message update', () async {
        when(attendance.checkIn(any)).thenAnswer(
          (_) async => const AttendanceNotAtOffice(
            GeofenceOutside(260, radiusMetres: 200),
          ),
        );
        final model = TodayViewModel();

        expect(await model.onSlideConfirmed(), isFalse);
        expect(model.location, isA<LocationOutside>());
        expect(model.actionMessage, AppStrings.outsideOffice(260, 200));
      });

      test('a location failure opens the permission sheet', () async {
        final sheets = getAndRegisterBottomSheetService();
        when(attendance.checkIn(any)).thenAnswer(
          (_) async =>
              const AttendanceLocationFailed(LocationFailure.deniedForever),
        );
        final model = TodayViewModel();

        expect(await model.onSlideConfirmed(), isFalse);
        expect(model.location, isA<LocationBlocked>());
        verify(
          sheets.showCustomSheet(
            variant: BottomSheetType.locationPermission,
            data: LocationFailure.deniedForever,
            isScrollControlled: true,
          ),
        ).called(1);
      });

      test('an unexpected error is shown as a message', () async {
        when(attendance.checkIn(any)).thenThrow(StateError('disk full'));
        final model = TodayViewModel();

        expect(await model.onSlideConfirmed(), isFalse);
        expect(model.actionMessage, AppStrings.unexpectedError);
        expect(model.isSubmitting, isFalse);
      });

      test('checked in: elapsed time and shift progress', () {
        when(attendance.today).thenReturn(_checkedInToday);
        final model = TodayViewModel();

        // Checked in 03:02 UTC, now 04:00 UTC.
        expect(model.elapsedLabel, '0:58:00');
        expect(model.shiftProgress, closeTo(58 / 540, 0.0001));
        expect(model.ringCaption, AppStrings.ringCaption(9));
      });

      test('checked out: no slider, worked time shown', () {
        when(attendance.today).thenReturn(
          AttendanceDay(
            workDate: '2026-10-28',
            checkInAt: DateTime.utc(2026, 10, 28, 3, 11),
            checkOutAt: DateTime.utc(2026, 10, 28, 12, 22),
          ),
        );
        final model = TodayViewModel();

        expect(model.showSlider, isFalse);
        expect(model.elapsedLabel, isEmpty);
        expect(model.workedTodayLabel, AppStrings.workedToday('9h 11m'));
      });
    });
  });
}
