import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/models/attendance_event.dart';
import 'package:rebs_hrms/models/attendance_event_type.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/sync_state.dart';
import 'package:rebs_hrms/services/database_service.dart';
import 'package:rebs_hrms/services/outbox_service.dart';

import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';

AttendanceEvent _event(
  String id,
  AttendanceEventType type, {
  String workDate = '2026-10-28',
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
    );

void main() {
  group('OutboxService -', () {
    late DatabaseService database;
    late OutboxService outbox;

    setUp(() async {
      registerServices();
      database = await useRealStorage();
      outbox = locator<OutboxService>();
    });

    tearDown(() async {
      await database.close();
      await locator.reset();
    });

    test('enqueue assigns increasing seq numbers', () async {
      final first =
          await outbox.enqueue(_event('a', AttendanceEventType.checkIn));
      final second =
          await outbox.enqueue(_event('b', AttendanceEventType.checkOut));

      expect(first?.seq, isNotNull);
      expect(second!.seq!, greaterThan(first!.seq!));
    });

    test('a second event of the same type for the day is refused', () async {
      await outbox.enqueue(_event('a', AttendanceEventType.checkIn));
      final duplicate =
          await outbox.enqueue(_event('b', AttendanceEventType.checkIn));

      expect(duplicate, isNull);
      expect(await outbox.activeEventsFor(['2026-10-28']), hasLength(1));
    });

    test('a rejected event frees the day for a new one', () async {
      final first =
          await outbox.enqueue(_event('a', AttendanceEventType.checkIn));
      await outbox.update(first!.copyWith(status: SyncState.rejected));

      final retry =
          await outbox.enqueue(_event('b', AttendanceEventType.checkIn));

      expect(retry, isNotNull);
    });

    test('nextPending returns the oldest pending event', () async {
      final first =
          await outbox.enqueue(_event('a', AttendanceEventType.checkIn));
      await outbox.enqueue(_event('b', AttendanceEventType.checkOut));

      expect((await outbox.nextPending())?.eventId, 'a');

      await outbox.update(first!.copyWith(status: SyncState.synced));
      expect((await outbox.nextPending())?.eventId, 'b');
    });

    test('update writes status, attempts and error', () async {
      final event =
          await outbox.enqueue(_event('a', AttendanceEventType.checkIn));
      await outbox.update(
        event!.copyWith(
          status: SyncState.rejected,
          attempts: 2,
          lastError: 'Already checked in',
        ),
      );

      final rows = await database.db.query('outbox');
      final stored = AttendanceEvent.fromRow(rows.single);
      expect(stored.status, SyncState.rejected);
      expect(stored.attempts, 2);
      expect(stored.lastError, 'Already checked in');
    });

    test('resetStuckSyncing puts in-flight events back to pending', () async {
      final event =
          await outbox.enqueue(_event('a', AttendanceEventType.checkIn));
      await outbox.update(event!.copyWith(status: SyncState.syncing));

      expect(await outbox.resetStuckSyncing(), 1);
      expect((await outbox.nextPending())?.eventId, 'a');
    });
  });
}
