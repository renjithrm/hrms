import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/exceptions/attendance_conflict_exception.dart';
import 'package:rebs_hrms/exceptions/request_timeout_exception.dart';
import 'package:rebs_hrms/exceptions/server_exception.dart';
import 'package:rebs_hrms/models/attendance_event.dart';
import 'package:rebs_hrms/models/attendance_event_type.dart';
import 'package:rebs_hrms/models/attendance_record.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/location_reading.dart';
import 'package:rebs_hrms/models/sync_summary.dart';
import 'package:rebs_hrms/policies/attendance_policy.dart';
import 'package:rebs_hrms/policies/geofence_policy.dart';
import 'package:rebs_hrms/services/api_service.dart';
import 'package:rebs_hrms/services/attendance_service.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/services/database_service.dart';
import 'package:rebs_hrms/services/outbox_service.dart';
import 'package:rebs_hrms/services/sync_service.dart';

import '../helpers/database_test_helper.dart';
import '../helpers/fixtures.dart';
import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

const _atOffice = GeoPosition(
  latitude: 10.0159,
  longitude: 76.3419,
  accuracyMetres: 12,
);

AttendanceEvent _event(String id, AttendanceEventType type) => AttendanceEvent(
      eventId: id,
      type: type,
      workDate: '2026-10-28',
      occurredAt: DateTime.utc(2026, 10, 28, 3, 2),
      position: _atOffice,
    );

/// A server that keeps one record per event ID, like the real one.
class _Server {
  final processed = <String, AttendanceEvent>{};
  final received = <String>[];

  AttendanceSubmission accept(AttendanceEvent event) {
    received.add(event.eventId);
    final replay = processed.containsKey(event.eventId);
    processed.putIfAbsent(event.eventId, () => event);
    return AttendanceSubmission(
      record: AttendanceRecord(
        workDate: event.workDate,
        checkInAt: DateTime.utc(2026, 10, 28, 3, 2),
      ),
      wasReplay: replay,
    );
  }
}

void main() {
  group('SyncService -', () {
    late DatabaseService database;
    late MockApiService api;
    late MockConnectivityService connectivity;
    late OutboxService outbox;
    late DateTime now;
    late SyncService sync;

    SyncService createSync() {
      final service = SyncService();
      locator
        ..unregister<SyncService>()
        ..registerSingleton<SyncService>(service);
      return service;
    }

    Future<List<String>> statuses() async =>
        (await database.db.query('outbox', orderBy: 'seq'))
            .map((row) => row['status'] as String)
            .toList();

    setUp(() async {
      registerServices();
      database = await useRealStorage();
      now = testNow;
      locator
        ..unregister<ClockService>()
        ..registerSingleton<ClockService>(
          ClockService(now: () => now, timezone: 'Asia/Kolkata'),
        );
      outbox = locator<OutboxService>();
      api = getAndRegisterApiService();
      connectivity = getAndRegisterConnectivityService();
      when(connectivity.isOnline).thenReturn(true);
      when(connectivity.backOnline$).thenAnswer((_) => const Stream.empty());
      final lifecycle = getAndRegisterAppLifecycleService();
      when(lifecycle.resumed$).thenAnswer((_) => const Stream.empty());
      sync = createSync();
    });

    tearDown(() async {
      await sync.stop();
      await database.close();
      await locator.reset();
    });

    test('sends in seq order and marks everything synced', () async {
      final server = _Server();
      when(api.submitAttendanceEvent(any)).thenAnswer(
        (i) async =>
            server.accept(i.positionalArguments.first as AttendanceEvent),
      );
      await outbox.enqueue(_event('in', AttendanceEventType.checkIn));
      await outbox.enqueue(_event('out', AttendanceEventType.checkOut));

      await sync.syncNow();

      expect(server.received, ['in', 'out']);
      expect(await statuses(), ['SYNCED', 'SYNCED']);
      expect(sync.summary, isA<SyncAllSynced>());
    });

    test('a check-out waits while its check-in stays pending', () async {
      when(api.submitAttendanceEvent(any))
          .thenThrow(const ServerException(503));
      await outbox.enqueue(_event('in', AttendanceEventType.checkIn));
      await outbox.enqueue(_event('out', AttendanceEventType.checkOut));

      await sync.syncNow();

      verify(api.submitAttendanceEvent(any)).called(1);
      expect(await statuses(), ['PENDING', 'PENDING']);
      expect((sync.summary as SyncWaiting).count, 2);
    });

    test('a retryable failure backs off before the next attempt', () async {
      when(api.submitAttendanceEvent(any))
          .thenThrow(const RequestTimeoutException());
      await outbox.enqueue(_event('in', AttendanceEventType.checkIn));

      await sync.syncNow();
      await sync.syncNow();
      verify(api.submitAttendanceEvent(any)).called(1);

      now = now.add(SyncService.backoffFor(1));
      await sync.syncNow();
      verify(api.submitAttendanceEvent(any)).called(1);

      final event = await outbox.nextPending();
      expect(event?.attempts, 2);
      expect(event?.nextAttemptAt, now.add(SyncService.backoffFor(2)));
    });

    test('Sync now ignores the backoff', () async {
      when(api.submitAttendanceEvent(any))
          .thenThrow(const RequestTimeoutException());
      await outbox.enqueue(_event('in', AttendanceEventType.checkIn));
      await sync.syncNow();

      await sync.syncNow(ignoreBackoff: true);

      verify(api.submitAttendanceEvent(any)).called(2);
    });

    test('backoff doubles up to five minutes', () {
      expect(SyncService.backoffFor(1), const Duration(seconds: 5));
      expect(SyncService.backoffFor(2), const Duration(seconds: 10));
      expect(SyncService.backoffFor(4), const Duration(seconds: 40));
      expect(SyncService.backoffFor(20), SyncService.maxBackoff);
    });

    test('a conflict is rejected with its reason and the queue moves on',
        () async {
      final server = _Server();
      when(api.submitAttendanceEvent(any)).thenAnswer((i) async {
        final event = i.positionalArguments.first as AttendanceEvent;
        if (event.eventId == 'in') {
          throw const AttendanceConflictException(
            code: 'ATTENDANCE_EXISTS',
            message: 'You have already checked in today.',
          );
        }
        return server.accept(event);
      });
      await outbox.enqueue(_event('in', AttendanceEventType.checkIn));
      await outbox.enqueue(_event('out', AttendanceEventType.checkOut));

      await sync.syncNow();

      expect(await statuses(), ['REJECTED', 'SYNCED']);
      expect(sync.queue.first.lastError, 'You have already checked in today.');
      expect((sync.summary as SyncNeedsAttention).count, 1);

      await sync.dismiss('in');
      expect(sync.queue.map((e) => e.eventId), ['out']);
      expect(sync.summary, isA<SyncAllSynced>());
    });

    test('offline: nothing is attempted and the pill says waiting', () async {
      when(connectivity.isOnline).thenReturn(false);
      await outbox.enqueue(_event('in', AttendanceEventType.checkIn));

      await sync.syncNow();

      verifyNever(api.submitAttendanceEvent(any));
      expect((sync.summary as SyncWaiting).count, 1);
    });

    test('calls during a run share it and go round once more', () async {
      final server = _Server();
      when(api.submitAttendanceEvent(any)).thenAnswer(
        (i) async =>
            server.accept(i.positionalArguments.first as AttendanceEvent),
      );
      await outbox.enqueue(_event('in', AttendanceEventType.checkIn));

      final first = sync.syncNow();
      await outbox.enqueue(_event('out', AttendanceEventType.checkOut));
      final second = sync.syncNow();
      expect(sync.isSyncing, isTrue);
      await Future.wait([first, second]);

      expect(server.received, ['in', 'out']);
      expect(sync.isSyncing, isFalse);
    });

    test(
        'required test 2 (part 2): timeout after the server committed, '
        'retry with the same ID, server holds one record', () async {
      final server = _Server();
      var calls = 0;
      when(api.submitAttendanceEvent(any)).thenAnswer((i) async {
        final result =
            server.accept(i.positionalArguments.first as AttendanceEvent);
        // The first response is lost on the way back.
        if (++calls == 1) throw const RequestTimeoutException();
        return result;
      });
      await outbox.enqueue(_event('in', AttendanceEventType.checkIn));

      await sync.syncNow();
      expect(await statuses(), ['PENDING']);

      now = now.add(SyncService.backoffFor(1));
      await sync.syncNow();

      expect(server.received, ['in', 'in']);
      expect(server.processed, hasLength(1));
      expect(await statuses(), ['SYNCED']);
      final cached = await database.db.query('attendance');
      expect(cached.single['work_date'], '2026-10-28');
    });

    test(
        'required test 3: saved offline, database closed and reopened, '
        'then synced as check-in before check-out', () async {
      final directory = await Directory.systemTemp.createTemp('rebs_sync_');
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/rebs.db';

      // First app session: offline check-in and check-out.
      await database.close();
      database = await openTestDatabase(path: path);
      locator
        ..unregister<DatabaseService>()
        ..registerSingleton<DatabaseService>(database)
        ..unregister<OutboxService>()
        ..registerSingleton<OutboxService>(OutboxService())
        ..unregister<GeofencePolicy>()
        ..registerSingleton<GeofencePolicy>(GeofencePolicy())
        ..unregister<AttendancePolicy>()
        ..registerSingleton<AttendancePolicy>(AttendancePolicy());
      await sync.stop();
      sync = createSync();
      when(connectivity.isOnline).thenReturn(false);
      final location = getAndRegisterLocationService();
      when(location.read(any, askPermission: anyNamed('askPermission')))
          .thenAnswer((_) async => const LocationFix(_atOffice));
      final attendance = AttendanceService();
      await attendance.checkIn(testEmployee.office);
      now = now.add(const Duration(hours: 9));
      await attendance.checkOut(testEmployee.office);
      verifyNever(api.submitAttendanceEvent(any));
      await database.close();

      // Second app session: reopen, back online, sync.
      database = await openTestDatabase(path: path);
      locator
        ..unregister<DatabaseService>()
        ..registerSingleton<DatabaseService>(database)
        ..unregister<OutboxService>()
        ..registerSingleton<OutboxService>(OutboxService());
      await sync.stop();
      sync = createSync();
      when(connectivity.isOnline).thenReturn(true);
      final server = _Server();
      final types = <AttendanceEventType>[];
      when(api.submitAttendanceEvent(any)).thenAnswer((i) async {
        final event = i.positionalArguments.first as AttendanceEvent;
        types.add(event.type);
        return server.accept(event);
      });

      await sync.start();
      await sync.syncNow();

      expect(
          types, [AttendanceEventType.checkIn, AttendanceEventType.checkOut]);
      expect(await statuses(), ['SYNCED', 'SYNCED']);
    });
  });
}
