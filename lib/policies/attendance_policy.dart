// lib/policies/attendance_policy.dart

import '../models/attendance_event.dart';
import '../models/attendance_event_type.dart';
import '../models/attendance_record.dart';
import '../models/attendance_rule_violation.dart';
import '../models/sync_state.dart';

/// Attendance rules for one working day: one check-in, and check-out only
/// after check-in. Pure Dart, so the server can mirror it exactly.
class AttendancePolicy {
  /// Checks whether [action] is allowed for the day described by
  /// [serverRecord] and the device's [localEvents] for the same day.
  ///
  /// Rejected local events are ignored: the server never accepted them.
  /// Returns null when the action is allowed.
  AttendanceRuleViolation? evaluate({
    required AttendanceEventType action,
    required AttendanceRecord? serverRecord,
    required List<AttendanceEvent> localEvents,
  }) {
    final live = localEvents.where((e) => e.status != SyncState.rejected);
    final hasCheckIn = serverRecord?.checkInAt != null ||
        live.any((e) => e.type == AttendanceEventType.checkIn);
    final hasCheckOut = serverRecord?.checkOutAt != null ||
        live.any((e) => e.type == AttendanceEventType.checkOut);

    switch (action) {
      case AttendanceEventType.checkIn:
        return hasCheckIn ? AttendanceRuleViolation.alreadyCheckedIn : null;
      case AttendanceEventType.checkOut:
        if (!hasCheckIn) return AttendanceRuleViolation.checkOutBeforeCheckIn;
        if (hasCheckOut) return AttendanceRuleViolation.alreadyCheckedOut;
        return null;
    }
  }
}
