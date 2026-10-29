import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/models/attendance_event.dart';
import 'package:rebs_hrms/models/attendance_event_type.dart';
import 'package:rebs_hrms/models/attendance_record.dart';
import 'package:rebs_hrms/models/attendance_rule_violation.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/sync_state.dart';
import 'package:rebs_hrms/policies/attendance_policy.dart';

AttendanceEvent _event(
  AttendanceEventType type, {
  SyncState status = SyncState.pending,
}) =>
    AttendanceEvent(
      eventId: '${type.name}-${status.name}',
      type: type,
      workDate: '2026-10-28',
      occurredAt: DateTime.utc(2026, 10, 28, 3),
      position: const GeoPosition(
        latitude: 10.0159,
        longitude: 76.3419,
        accuracyMetres: 10,
      ),
      status: status,
    );

void main() {
  final policy = AttendancePolicy();

  group('AttendancePolicy -', () {
    group('check-out without check-in (required test 1) -', () {
      test('is rejected when there is no record and no local event', () {
        final result = policy.evaluate(
          action: AttendanceEventType.checkOut,
          serverRecord: null,
          localEvents: const [],
        );
        expect(result, AttendanceRuleViolation.checkOutBeforeCheckIn);
      });

      test('is rejected when the only check-in was rejected by the server', () {
        final result = policy.evaluate(
          action: AttendanceEventType.checkOut,
          serverRecord: null,
          localEvents: [
            _event(AttendanceEventType.checkIn, status: SyncState.rejected),
          ],
        );
        expect(result, AttendanceRuleViolation.checkOutBeforeCheckIn);
      });

      test('is allowed after a check-in that is still pending sync', () {
        final result = policy.evaluate(
          action: AttendanceEventType.checkOut,
          serverRecord: null,
          localEvents: [_event(AttendanceEventType.checkIn)],
        );
        expect(result, isNull);
      });

      test('is allowed after a check-in the server already has', () {
        final result = policy.evaluate(
          action: AttendanceEventType.checkOut,
          serverRecord: AttendanceRecord(
            workDate: '2026-10-28',
            checkInAt: DateTime.utc(2026, 10, 28, 3),
          ),
          localEvents: const [],
        );
        expect(result, isNull);
      });
    });

    test('a second check-in on the same day is rejected', () {
      final result = policy.evaluate(
        action: AttendanceEventType.checkIn,
        serverRecord: null,
        localEvents: [_event(AttendanceEventType.checkIn)],
      );
      expect(result, AttendanceRuleViolation.alreadyCheckedIn);
    });

    test('a second check-out on the same day is rejected', () {
      final result = policy.evaluate(
        action: AttendanceEventType.checkOut,
        serverRecord: AttendanceRecord(
          workDate: '2026-10-28',
          checkInAt: DateTime.utc(2026, 10, 28, 3),
          checkOutAt: DateTime.utc(2026, 10, 28, 12),
        ),
        localEvents: const [],
      );
      expect(result, AttendanceRuleViolation.alreadyCheckedOut);
    });

    test('the first check-in of the day is allowed', () {
      final result = policy.evaluate(
        action: AttendanceEventType.checkIn,
        serverRecord: null,
        localEvents: const [],
      );
      expect(result, isNull);
    });
  });
}
