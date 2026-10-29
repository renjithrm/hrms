import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/app/app.router.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/models/leave_balance.dart';
import 'package:rebs_hrms/models/leave_filter.dart';
import 'package:rebs_hrms/models/leave_request.dart';
import 'package:rebs_hrms/models/leave_status.dart';
import 'package:rebs_hrms/models/leave_type.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/ui/views/leave/leave_viewmodel.dart';

import '../helpers/navigation_matchers.dart';
import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

LeaveRequest _request(
  String id,
  LeaveStatus status, {
  int start = 5,
  int end = 6,
  int month = 11,
  String? note,
}) =>
    LeaveRequest(
      id: id,
      type: LeaveType.casual,
      startDate: DateTime.utc(2026, month, start),
      endDate: DateTime.utc(2026, month, end),
      reason: 'Family function in Thrissur',
      status: status,
      reviewerNote: note,
    );

final _requests = [
  _request('p', LeaveStatus.pending),
  _request('a', LeaveStatus.approved, start: 14, end: 14, month: 10),
  _request(
    'r',
    LeaveStatus.rejected,
    start: 2,
    end: 4,
    month: 9,
    note: 'Release week, please reschedule',
  ),
];

void main() {
  group('LeaveViewModel -', () {
    late MockLeaveService leave;
    late MockConnectivityService connectivity;

    setUp(() {
      registerServices();
      locator
        ..unregister<ClockService>()
        ..registerSingleton<ClockService>(
          ClockService(now: () => testNow, timezone: 'Asia/Kolkata'),
        );
      leave = getAndRegisterLeaveService();
      when(leave.requests).thenReturn(_requests);
      when(leave.balances).thenReturn(const [
        LeaveBalance(
          type: LeaveType.casual,
          entitlement: 10,
          used: 2,
          onHold: 2,
          available: 6,
        ),
      ]);
      when(leave.hasCache).thenReturn(true);
      when(leave.lastUpdated).thenReturn(testNow);
      when(leave.loadCached()).thenAnswer((_) async {});
      when(leave.refresh()).thenAnswer((_) async {});
      connectivity = getAndRegisterConnectivityService();
      when(connectivity.isOnline).thenReturn(true);
    });

    tearDown(() => locator.reset());

    test('loads the cache then refreshes', () async {
      final model = LeaveViewModel();
      await model.init();

      verifyInOrder([leave.loadCached(), leave.refresh()]);
      expect(model.hasError, isFalse);
      expect(model.bannerMessage, isNull);
      expect(model.requests, hasLength(3));
    });

    test('filters by status, with a pending count on its chip', () {
      final model = LeaveViewModel();

      expect(
        model.filterLabelOf(LeaveFilter.pending),
        AppStrings.filterWithCount(AppStrings.leavePending, 1),
      );
      model.selectFilter(LeaveFilter.approved);
      expect(model.requests.map((r) => r.id), ['a']);
      model.selectFilter(LeaveFilter.rejected);
      expect(model.requests.map((r) => r.id), ['r']);
      model.selectFilter(LeaveFilter.all);
      expect(model.requests, hasLength(3));
    });

    test('an empty filter says which status has none', () {
      when(leave.requests).thenReturn([_requests.first]);
      final model = LeaveViewModel()..selectFilter(LeaveFilter.rejected);

      expect(model.showEmptyList, isTrue);
      expect(
        model.emptyTitle,
        AppStrings.leaveFilterEmpty(AppStrings.leaveRejected),
      );
    });

    test('rows: badge, range, days and reason; rejected shows the note', () {
      final model = LeaveViewModel();
      final [pending, approved, rejected] = _requests;

      expect(model.badgeOf(pending), '5 Nov');
      expect(model.titleOf(pending), 'Casual · 5–6 Nov');
      expect(model.detailOf(pending), '2 days · Family function in Thrissur');
      expect(model.titleOf(approved), 'Casual · 14 Oct');
      expect(model.detailOf(rejected), 'Release week, please reschedule');
      expect(model.statusOf(rejected), AppStrings.leaveRejected);
    });

    test('balances show days on hold', () {
      final model = LeaveViewModel();

      expect(model.onHoldOf(model.balances.single), AppStrings.leaveOnHold(2));
    });

    test('online: Apply opens the apply flow, then refreshes', () async {
      final navigation = getAndRegisterNavigationService();
      final model = LeaveViewModel();

      expect(model.canApply, isTrue);
      expect(model.applyLabel, AppStrings.applyForLeave);
      await model.applyForLeave();

      verifyNavigatedTo(navigation, Routes.applyLeaveView);
      verify(leave.refresh()).called(1);
    });

    test('offline: Apply is disabled and says it needs a connection', () async {
      when(connectivity.isOnline).thenReturn(false);
      final navigation = getAndRegisterNavigationService();
      final model = LeaveViewModel();

      expect(model.canApply, isFalse);
      expect(model.applyLabel, AppStrings.needsConnection);
      await model.applyForLeave();

      verifyNever(
        navigation.navigateTo(
          any,
          arguments: anyNamed('arguments'),
          id: anyNamed('id'),
          preventDuplicates: anyNamed('preventDuplicates'),
          parameters: anyNamed('parameters'),
          transition: anyNamed('transition'),
        ),
      );
    });

    test('offline with a cache: the cached list shows with a banner', () async {
      when(connectivity.isOnline).thenReturn(false);
      when(leave.refresh()).thenThrow(const OfflineException());
      final model = LeaveViewModel();
      await model.init();

      expect(model.showFullError, isFalse);
      expect(model.requests, hasLength(3));
      expect(model.bannerMessage, AppStrings.offlineBanner('28 Oct, 09:30'));
    });

    test('nothing cached and the download fails: full error', () async {
      when(leave.hasCache).thenReturn(false);
      when(leave.lastUpdated).thenReturn(null);
      when(leave.requests).thenReturn(const []);
      when(leave.refresh()).thenThrow(const OfflineException());
      final model = LeaveViewModel();
      await model.init();

      expect(model.showFullError, isTrue);
      expect(model.errorMessage, AppStrings.offline);
      expect(model.showEmptyList, isFalse);
    });
  });
}
