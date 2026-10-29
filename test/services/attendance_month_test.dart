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
import 'package:rebs_hrms/services/outbox_service.dart';

import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

AttendanceRecord _record(String date) => AttendanceRecord(
      workDate: date,
      checkInAt: DateTime.parse('${date}T03:10:00Z'),
      checkOutAt: DateTime.parse('${date}T12:20:00Z'),
    );

void main() {
  group('AttendanceService months -', () {
    late DatabaseService database;
    late MockApiService api;

    setUp(() async {
      registerServices();
      database = await useRealStorage();
      api = getAndRegisterApiService();
    });

    tearDown(() async {
      await database.close();
      await locator.reset();
    });

    test('a month never downloaded is empty with no timestamp', () async {
      final month = await AttendanceService().cachedMonth('2026-09');

      expect(month.days, isEmpty);
      expect(month.updatedAt, isNull);
    });

    test('a viewed month stays readable offline', () async {
      when(api.fetchAttendance('2026-09')).thenAnswer(
        (_) async => [_record('2026-09-02'), _record('2026-09-01')],
      );
      await AttendanceService().refreshMonth('2026-09');

      // Next launch, offline.
      when(api.fetchAttendance(any)).thenThrow(const OfflineException());
      final service = AttendanceService();
      await expectLater(
        service.refreshMonth('2026-09'),
        throwsA(isA<OfflineException>()),
      );
      final month = await service.cachedMonth('2026-09');

      expect(month.days.map((d) => d.workDate), ['2026-09-01', '2026-09-02']);
      expect(month.updatedAt, testNow);
    });

    test('a refresh replaces the month but leaves other months alone',
        () async {
      final service = AttendanceService();
      when(api.fetchAttendance('2026-09'))
          .thenAnswer((_) async => [_record('2026-09-01')]);
      when(api.fetchAttendance('2026-08'))
          .thenAnswer((_) async => [_record('2026-08-31')]);
      await service.refreshMonth('2026-09');
      await service.refreshMonth('2026-08');

      when(api.fetchAttendance('2026-09')).thenAnswer((_) async => []);
      await service.refreshMonth('2026-09');

      expect((await service.cachedMonth('2026-09')).days, isEmpty);
      expect((await service.cachedMonth('2026-08')).days, hasLength(1));
    });

    test('local events show in their month before the server has them',
        () async {
      await locator<OutboxService>().enqueue(
        AttendanceEvent(
          eventId: 'e1',
          type: AttendanceEventType.checkIn,
          workDate: '2026-10-28',
          occurredAt: DateTime.utc(2026, 10, 28, 3, 2),
          position: const GeoPosition(
            latitude: 10.0159,
            longitude: 76.3419,
            accuracyMetres: 12,
          ),
        ),
      );

      final month = await AttendanceService().cachedMonth('2026-10');

      expect(month.days.single.checkInState, SyncState.pending);
    });

    test('clearToday forgets today here and keeps other days', () async {
      when(api.fetchAttendance('2026-10')).thenAnswer(
        (_) async => [_record('2026-10-28'), _record('2026-10-27')],
      );
      final service = AttendanceService();
      await service.refreshMonth('2026-10');
      await locator<OutboxService>().enqueue(
        AttendanceEvent(
          eventId: 'e1',
          type: AttendanceEventType.checkOut,
          workDate: '2026-10-28',
          occurredAt: DateTime.utc(2026, 10, 28, 12),
          position: const GeoPosition(
            latitude: 10.0159,
            longitude: 76.3419,
            accuracyMetres: 12,
          ),
        ),
      );
      await service.loadCached();
      expect(service.today, isNotNull);

      await service.clearToday();

      expect(service.today, isNull);
      expect(await database.db.query('outbox'), isEmpty);
      final month = await service.cachedMonth('2026-10');
      expect(month.days.map((d) => d.workDate), ['2026-10-27']);
    });
  });
}
