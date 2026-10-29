// lib/models/attendance_rule_violation.dart

/// Reasons a check-in or check-out is not allowed right now.
enum AttendanceRuleViolation {
  /// A check-in already exists for the working day.
  alreadyCheckedIn,

  /// Check-out was requested before any check-in.
  checkOutBeforeCheckIn,

  /// A check-out already exists for the working day.
  alreadyCheckedOut,
}
