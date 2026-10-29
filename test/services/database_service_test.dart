import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/models/attendance_event.dart';
import 'package:rebs_hrms/models/attendance_event_type.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/sync_state.dart';
import 'package:rebs_hrms/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/database_test_helper.dart';

AttendanceEvent _event(
  String id,
  AttendanceEventType type, {
  SyncState status = SyncState.pending,
}) =>
    AttendanceEvent(
      eventId: id,
      type: type,
      workDate: '2026-10-28',
      occurredAt: DateTime.utc(2026, 10, 28, 3),
      position: const GeoPosition(
        latitude: 10.0159,
        longitude: 76.3419,
        accuracyMetres: 12,
      ),
      status: status,
    );

void main() {
  group('DatabaseService -', () {
    late DatabaseService service;

    setUp(() async => service = await openTestDatabase());
    tearDown(() => service.close());

    test('assigns increasing seq numbers in insertion order', () async {
      final first = await service.db
          .insert('outbox', _event('a', AttendanceEventType.checkIn).toRow());
      final second = await service.db
          .insert('outbox', _event('b', AttendanceEventType.checkOut).toRow());
      expect(second, greaterThan(first));
    });

    test('refuses a second check-in for the same day', () async {
      await service.db
          .insert('outbox', _event('a', AttendanceEventType.checkIn).toRow());
      expect(
        () => service.db
            .insert('outbox', _event('b', AttendanceEventType.checkIn).toRow()),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('allows a new check-in once the earlier one was rejected', () async {
      await service.db.insert(
        'outbox',
        _event('a', AttendanceEventType.checkIn, status: SyncState.rejected)
            .toRow(),
      );
      await service.db
          .insert('outbox', _event('b', AttendanceEventType.checkIn).toRow());
      final rows = await service.db.query('outbox');
      expect(rows, hasLength(2));
    });

    test('refuses the same event ID twice', () async {
      await service.db.insert(
        'outbox',
        _event('same', AttendanceEventType.checkIn, status: SyncState.rejected)
            .toRow(),
      );
      expect(
        () => service.db.insert(
          'outbox',
          _event('same', AttendanceEventType.checkOut).toRow(),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  test('DatabaseService - data survives closing and reopening the file',
      () async {
    final dir = await Directory.systemTemp.createTemp('rebs_db_');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/test.db';

    final first = await openTestDatabase(path: path);
    await first.db
        .insert('outbox', _event('a', AttendanceEventType.checkIn).toRow());
    await first.close();

    final reopened = await openTestDatabase(path: path);
    addTearDown(reopened.close);
    final rows = await reopened.db.query('outbox');
    expect(AttendanceEvent.fromRow(rows.single).eventId, 'a');
  });
}
