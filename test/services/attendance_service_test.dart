import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/models/attendance_event.dart';
import 'package:rebs_hrms/models/attendance_event_type.dart';
import 'package:rebs_hrms/models/attendance_record.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/sync_state.dart';
import 'package:rebs_hrms/services/attendance_service.dart';
import 'package:rebs_hrms/services/database_service.dart';

import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

AttendanceRecord _record(int day, {bool out = true}) => AttendanceRecord(
      workDate: '2026-10-${day.toString().padLeft(2, '0')}',
      checkInAt: DateTime.utc(2026, 10, day, 3, 10),
      checkOutAt: out ? DateTime.utc(2026, 10, day, 12, 20) : null,
    );

AttendanceEvent _local(
  String id,
  AttendanceEventType type, {
  String workDate = '2026-10-28',
  SyncState status = SyncState.pending,
}) =>
    AttendanceEvent(
      eventId: id,
      type: type,
      workDate: workDate,
      occurredAt: DateTime.utc(2026, 10, 28, 3, 2),
      position: const GeoPosition(
        latitude: 10.0159,
        longitude: 76.3419,
        accuracyMetres: 12,
      ),
      status: status,
    );

void main() {
  group('AttendanceService -', () {
    late DatabaseService database;
    late MockApiService api;

    setUp(() async {
      registerServices();
      database = await useRealStorage();
      api = getAndRegisterApiService();
      when(api.fetchAttendance('2026-10')).thenAnswer(
        (_) async => [27, 26, 23, 22, 21, 20].map(_record).toList(),
      );
    });

    tearDown(() async {
      await database.close();
      await locator.reset();
    });

    test('refresh keeps the latest five days, newest first', () async {
      final service = AttendanceService();
      await service.refresh();

      expect(service.recent.map((d) => d.workDate), [
        '2026-10-27',
        '2026-10-26',
        '2026-10-23',
        '2026-10-22',
        '2026-10-21',
      ]);
      expect(service.today, isNull);
      expect(service.hasCache, isTrue);
      verifyNever(api.fetchAttendance('2026-09'));
    });

    test('cached history is available on the next launch offline', () async {
      await AttendanceService().refresh();
      when(api.fetchAttendance(any)).thenThrow(const OfflineException());

      final nextLaunch = AttendanceService();
      await nextLaunch.loadCached();

      expect(nextLaunch.recent, hasLength(5));
      expect(nextLaunch.lastUpdated, testNow);
    });

    test('a check-in saved offline shows as today, waiting to sync', () async {
      await database.db.insert(
        'outbox',
        _local('a', AttendanceEventType.checkIn).toRow(),
      );
      final service = AttendanceService();
      await service.refresh();

      expect(service.today?.checkInAt, DateTime.utc(2026, 10, 28, 3, 2));
      expect(service.today?.checkInState, SyncState.pending);
      expect(service.recent.first.isWaitingToSync, isTrue);
    });

    test('the server record wins over a local copy of the same event',
        () async {
      when(api.fetchAttendance('2026-10')).thenAnswer(
        (_) async => [
          _record(28, out: false),
          _record(27),
          _record(26),
          _record(23),
          _record(22)
        ],
      );
      await database.db.insert(
        'outbox',
        _local('a', AttendanceEventType.checkIn, status: SyncState.synced)
            .toRow(),
      );
      final service = AttendanceService();
      await service.refresh();

      expect(service.today?.checkInAt, DateTime.utc(2026, 10, 28, 3, 10));
      expect(service.today?.checkInState, SyncState.synced);
    });

    test('rejected local events are ignored', () async {
      await database.db.insert(
        'outbox',
        _local('a', AttendanceEventType.checkIn, status: SyncState.rejected)
            .toRow(),
      );
      final service = AttendanceService();
      await service.refresh();

      expect(service.today, isNull);
    });

    test('early in a month it also fetches last month', () async {
      when(api.fetchAttendance('2026-10'))
          .thenAnswer((_) async => [_record(1), _record(2)]);
      when(api.fetchAttendance('2026-09')).thenAnswer(
        (_) async => [
          AttendanceRecord(
            workDate: '2026-09-30',
            checkInAt: DateTime.utc(2026, 9, 30, 3),
          ),
        ],
      );
      final service = AttendanceService();
      await service.refresh();

      expect(service.recent.last.workDate, '2026-09-30');
    });

    test('a failed refresh throws and keeps the cache', () async {
      final service = AttendanceService();
      await service.refresh();
      when(api.fetchAttendance(any)).thenThrow(const OfflineException());

      await expectLater(service.refresh(), throwsA(isA<OfflineException>()));
      expect(service.recent, hasLength(5));
    });
  });
}
