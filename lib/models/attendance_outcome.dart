// lib/models/attendance_outcome.dart

import 'attendance_event.dart';
import 'attendance_rule_violation.dart';
import 'geofence_result.dart';
import 'location_failure.dart';

/// What happened when the person slid to check in or out.
sealed class AttendanceOutcome {
  const AttendanceOutcome();
}

/// The event was saved on the device, and sent if possible.
class AttendanceRecorded extends AttendanceOutcome {
  /// Creates the outcome.
  const AttendanceRecorded(this.event, {required this.isSynced});

  /// The stored event.
  final AttendanceEvent event;

  /// Whether the server already has it.
  final bool isSynced;
}

/// The attendance rules don't allow the action.
class AttendanceRefused extends AttendanceOutcome {
  /// Creates the outcome.
  const AttendanceRefused(this.violation);

  /// Which rule.
  final AttendanceRuleViolation violation;
}

/// A fresh position put the person outside the office, or was too vague.
class AttendanceNotAtOffice extends AttendanceOutcome {
  /// Creates the outcome.
  const AttendanceNotAtOffice(this.result);

  /// Outside or inaccurate.
  final GeofenceResult result;
}

/// No position could be read.
class AttendanceLocationFailed extends AttendanceOutcome {
  /// Creates the outcome.
  const AttendanceLocationFailed(this.reason);

  /// Why.
  final LocationFailure reason;
}
