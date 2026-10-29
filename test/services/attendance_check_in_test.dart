import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/exceptions/attendance_conflict_exception.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/models/attendance_event.dart';
import 'package:rebs_hrms/models/attendance_outcome.dart';
import 'package:rebs_hrms/models/attendance_record.dart';
import 'package:rebs_hrms/models/attendance_rule_violation.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/location_failure.dart';
import 'package:rebs_hrms/models/location_reading.dart';
import 'package:rebs_hrms/models/sync_state.dart';
import 'package:rebs_hrms/policies/attendance_policy.dart';
import 'package:rebs_hrms/policies/geofence_policy.dart';
import 'package:rebs_hrms/services/api_service.dart';
import 'package:rebs_hrms/services/attendance_service.dart';
import 'package:rebs_hrms/services/database_service.dart';
import 'package:rebs_hrms/services/sync_service.dart';

import '../helpers/fixtures.dart';
import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

const _office = GeoPosition(
  latitude: 10.0159,
  longitude: 76.3419,
  accuracyMetres: 12,
);

void main() {
  group('AttendanceService check-in and check-out -', () {
    late DatabaseService database;
    late MockApiService api;
    late MockLocationService location;
    late SyncService sync;

    Future<List<Map<String, Object?>>> outboxRows() =>
        database.db.query('outbox', orderBy: 'seq');

    void serverAccepts() =>
        when(api.submitAttendanceEvent(any)).thenAnswer((invocation) async {
          final event = invocation.positionalArguments.first as AttendanceEvent;
          return AttendanceSubmission(
            record: AttendanceRecord(
              workDate: event.workDate,
              checkInAt: DateTime.utc(2026, 10, 28, 4),
            ),
            wasReplay: false,
          );
        });

    setUp(() async {
      registerServices();
      database = await useRealStorage();
      locator
        ..unregister<GeofencePolicy>()
        ..registerSingleton<GeofencePolicy>(GeofencePolicy())
        ..unregister<AttendancePolicy>()
        ..registerSingleton<AttendancePolicy>(AttendancePolicy());
      api = getAndRegisterApiService();
      final connectivity = getAndRegisterConnectivityService();
      when(connectivity.isOnline).thenReturn(true);
      when(connectivity.backOnline$).thenAnswer((_) => const Stream.empty());
      sync = SyncService();
      locator
        ..unregister<SyncService>()
        ..registerSingleton<SyncService>(sync);
      location = getAndRegisterLocationService();
      when(location.read(any, askPermission: anyNamed('askPermission')))
          .thenAnswer((_) async => const LocationFix(_office));
      serverAccepts();
    });

    tearDown(() async {
      await sync.stop();
      await database.close();
      await locator.reset();
    });

    test('check-in online is stored and synced', () async {
      final service = AttendanceService();

      final outcome = await service.checkIn(testEmployee.office);

      expect(outcome, isA<AttendanceRecorded>());
      expect((outcome as AttendanceRecorded).isSynced, isTrue);
      final rows = await outboxRows();
      expect(rows.single['status'], SyncState.synced.wireValue);
      expect(rows.single['work_date'], '2026-10-28');
      expect(service.today?.checkInAt, isNotNull);
    });

    test('check-in offline is saved on the phone, waiting to sync', () async {
      when(api.submitAttendanceEvent(any)).thenThrow(const OfflineException());
      final service = AttendanceService();

      final outcome = await service.checkIn(testEmployee.office);

      expect((outcome as AttendanceRecorded).isSynced, isFalse);
      final rows = await outboxRows();
      expect(rows.single['status'], SyncState.pending.wireValue);
      expect(rows.single['attempts'], 1);
      expect(service.today?.checkInState, SyncState.pending);
    });

    test('a server conflict marks the event rejected with its reason',
        () async {
      when(api.submitAttendanceEvent(any)).thenThrow(
        const AttendanceConflictException(
          code: 'ATTENDANCE_EXISTS',
          message: 'Attendance already exists for this day.',
        ),
      );

      final outcome = await AttendanceService().checkIn(testEmployee.office);

      expect((outcome as AttendanceRecorded).isSynced, isFalse);
      final rows = await outboxRows();
      expect(rows.single['status'], SyncState.rejected.wireValue);
      expect(
          rows.single['last_error'], 'Attendance already exists for this day.');
    });

    test('required test 2 (part 1): two concurrent check-ins create one row',
        () async {
      final service = AttendanceService();

      final outcomes = await Future.wait([
        service.checkIn(testEmployee.office),
        service.checkIn(testEmployee.office),
      ]);

      expect(await outboxRows(), hasLength(1));
      expect(outcomes.whereType<AttendanceRecorded>(), hasLength(1));
      final refused = outcomes.whereType<AttendanceRefused>().single;
      expect(refused.violation, AttendanceRuleViolation.alreadyCheckedIn);
      verify(api.submitAttendanceEvent(any)).called(1);
    });

    test('two services racing on one database still create one row', () async {
      // Separate services have separate locks; the unique index decides.
      final outcomes = await Future.wait([
        AttendanceService().checkIn(testEmployee.office),
        AttendanceService().checkIn(testEmployee.office),
      ]);

      expect(await outboxRows(), hasLength(1));
      expect(outcomes.whereType<AttendanceRecorded>(), hasLength(1));
    });

    test('check-out before check-in is refused and stores nothing', () async {
      final outcome = await AttendanceService().checkOut(testEmployee.office);

      expect(
        (outcome as AttendanceRefused).violation,
        AttendanceRuleViolation.checkOutBeforeCheckIn,
      );
      expect(await outboxRows(), isEmpty);
    });

    test('check-out after an offline check-in sends both, in order', () async {
      when(api.submitAttendanceEvent(any)).thenThrow(const OfflineException());
      final service = AttendanceService();
      await service.checkIn(testEmployee.office);

      serverAccepts();
      final outcome = await service.checkOut(testEmployee.office);

      expect((outcome as AttendanceRecorded).isSynced, isTrue);
      final sent = verify(api.submitAttendanceEvent(captureAny)).captured;
      expect(
        sent.cast<AttendanceEvent>().map((e) => e.type.wireValue),
        ['CHECK_IN', 'CHECK_IN', 'CHECK_OUT'],
      );
      final rows = await outboxRows();
      expect(rows.map((r) => r['status']), everyElement('SYNCED'));
    });

    test('outside the office nothing is stored', () async {
      when(location.read(any, askPermission: anyNamed('askPermission')))
          .thenAnswer(
        (_) async => const LocationFix(
          GeoPosition(latitude: 10.03, longitude: 76.3419, accuracyMetres: 12),
        ),
      );

      final outcome = await AttendanceService().checkIn(testEmployee.office);

      expect(outcome, isA<AttendanceNotAtOffice>());
      expect(await outboxRows(), isEmpty);
    });

    test('a location failure is reported and nothing is stored', () async {
      when(location.read(any, askPermission: anyNamed('askPermission')))
          .thenAnswer(
        (_) async => const LocationUnreadable(LocationFailure.deniedForever),
      );

      final outcome = await AttendanceService().checkIn(testEmployee.office);

      expect(
        (outcome as AttendanceLocationFailed).reason,
        LocationFailure.deniedForever,
      );
      expect(await outboxRows(), isEmpty);
    });
  });
}
