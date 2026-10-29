import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/models/leave_balance.dart';
import 'package:rebs_hrms/models/leave_input.dart';
import 'package:rebs_hrms/models/leave_request.dart';
import 'package:rebs_hrms/models/leave_status.dart';
import 'package:rebs_hrms/models/leave_type.dart';
import 'package:rebs_hrms/services/database_service.dart';
import 'package:rebs_hrms/services/leave_service.dart';

import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

LeaveRequest _request(String id, int startDay, LeaveStatus status) =>
    LeaveRequest(
      id: id,
      type: LeaveType.casual,
      startDate: DateTime.utc(2026, 11, startDay),
      endDate: DateTime.utc(2026, 11, startDay),
      reason: 'Family function in Thrissur',
      status: status,
    );

void main() {
  group('LeaveService -', () {
    late DatabaseService database;
    late MockApiService api;
    late MockConnectivityService connectivity;

    setUp(() async {
      registerServices();
      database = await useRealStorage();
      connectivity = getAndRegisterConnectivityService();
      when(connectivity.isOnline).thenReturn(true);
      api = getAndRegisterApiService();
      when(api.fetchLeaveBalances()).thenAnswer(
        (_) async => const [
          LeaveBalance(
            type: LeaveType.casual,
            entitlement: 10,
            used: 2,
            onHold: 2,
            available: 6,
          ),
        ],
      );
      when(api.fetchLeaveRequests()).thenAnswer(
        (_) async => [
          _request('L-1', 2, LeaveStatus.approved),
          _request('L-2', 9, LeaveStatus.pending),
        ],
      );
    });

    tearDown(() async {
      await database.close();
      await locator.reset();
    });

    test('refresh sorts requests by start date, newest first', () async {
      final service = LeaveService();
      await service.refresh();
      expect(service.requests.map((r) => r.id), ['L-2', 'L-1']);
      expect(service.balanceFor(LeaveType.casual)?.available, 6);
      expect(service.balanceFor(LeaveType.sick), isNull);
    });

    test('requests stay readable offline on the next launch', () async {
      await LeaveService().refresh();
      final nextLaunch = LeaveService();
      await nextLaunch.loadCached();

      expect(nextLaunch.requests, hasLength(2));
      expect(nextLaunch.requests.first.status, LeaveStatus.pending);
      expect(nextLaunch.hasCache, isTrue);
    });

    group('submit -', () {
      final input = LeaveInput(
        type: LeaveType.casual,
        startDate: DateTime.utc(2026, 11, 16),
        endDate: DateTime.utc(2026, 11, 17),
        reason: 'Sister\'s wedding in Kochi',
      );

      test('caches the new request first in the list, offline too', () async {
        final service = LeaveService();
        await service.refresh();
        when(api.submitLeave(any))
            .thenAnswer((_) async => _request('L-3', 16, LeaveStatus.pending));
        // The background refresh fails, so only the submit wrote L-3.
        when(api.fetchLeaveRequests()).thenThrow(const OfflineException());

        final created = await service.submit(input);

        expect(created.id, 'L-3');
        expect(service.requests.first.id, 'L-3');
        final reopened = LeaveService();
        await reopened.loadCached();
        expect(reopened.requests.map((r) => r.id), contains('L-3'));
      });

      test('offline: fails without calling the server', () async {
        when(connectivity.isOnline).thenReturn(false);

        await expectLater(
          LeaveService().submit(input),
          throwsA(isA<OfflineException>()),
        );
        verifyNever(api.submitLeave(any));
      });
    });
  });
}
