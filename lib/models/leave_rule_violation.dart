// lib/models/leave_rule_violation.dart

import 'leave_request.dart';

/// Form field a violation belongs to, so the form can show it in place.
enum LeaveField {
  /// The date range.
  dates,

  /// The reason text.
  reason,
}

/// A leave rule the current input breaks.
sealed class LeaveRuleViolation {
  const LeaveRuleViolation();

  /// Field the message is shown under.
  LeaveField get field;
}

/// Start or end date not chosen yet.
class LeaveDatesMissing extends LeaveRuleViolation {
  /// Creates the violation.
  const LeaveDatesMissing();

  @override
  LeaveField get field => LeaveField.dates;
}

/// Start date is before the company's today.
class LeaveStartBeforeToday extends LeaveRuleViolation {
  /// Creates the violation.
  const LeaveStartBeforeToday();

  @override
  LeaveField get field => LeaveField.dates;
}

/// End date is before the start date.
class LeaveEndBeforeStart extends LeaveRuleViolation {
  /// Creates the violation.
  const LeaveEndBeforeStart();

  @override
  LeaveField get field => LeaveField.dates;
}

/// Reason has fewer than 10 non-whitespace characters.
class LeaveReasonTooShort extends LeaveRuleViolation {
  /// Creates the violation.
  const LeaveReasonTooShort(this.count);

  /// Non-whitespace characters typed so far.
  final int count;

  @override
  LeaveField get field => LeaveField.reason;
}

/// More days requested than the balance allows.
class LeaveExceedsBalance extends LeaveRuleViolation {
  /// Creates the violation.
  const LeaveExceedsBalance({required this.requested, required this.available});

  /// Days in the chosen range.
  final int requested;

  /// Days available for the chosen type.
  final int available;

  @override
  LeaveField get field => LeaveField.dates;
}

/// The range shares days with a pending or approved request.
class LeaveOverlaps extends LeaveRuleViolation {
  /// Creates the violation.
  const LeaveOverlaps(this.existing);

  /// The request it collides with.
  final LeaveRequest existing;

  @override
  LeaveField get field => LeaveField.dates;
}
