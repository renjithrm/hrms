// lib/policies/leave_policy.dart

import '../extensions/date_time_extensions.dart';
import '../models/leave_balance.dart';
import '../models/leave_input.dart';
import '../models/leave_request.dart';
import '../models/leave_rule_violation.dart';

/// The brief's five leave rules. Returns every violation at once so the
/// form can show all problems together.
class LeavePolicy {
  /// Minimum reason length, not counting whitespace.
  static const int minReasonLength = 10;

  /// Validates [input] against the company's [today], the person's
  /// [balances] and their [existing] requests.
  List<LeaveRuleViolation> validate(
    LeaveInput input, {
    required DateTime today,
    required List<LeaveBalance> balances,
    required List<LeaveRequest> existing,
  }) {
    final violations = <LeaveRuleViolation>[];
    final start = input.startDate?.dateOnly;
    final end = input.endDate?.dateOnly;

    if (start == null || end == null) {
      violations.add(const LeaveDatesMissing());
    } else {
      if (start.isBefore(today.dateOnly)) {
        violations.add(const LeaveStartBeforeToday());
      }
      if (end.isBefore(start)) {
        violations.add(const LeaveEndBeforeStart());
      } else {
        final requested = start.daysUntil(end) + 1;
        final available = _availableFor(input, balances);
        if (requested > available) {
          violations.add(
            LeaveExceedsBalance(requested: requested, available: available),
          );
        }
        for (final request in existing) {
          if (request.blocksOverlap && request.overlaps(start, end)) {
            violations.add(LeaveOverlaps(request));
            break;
          }
        }
      }
    }

    final length = input.reasonLength;
    if (length < minReasonLength) violations.add(LeaveReasonTooShort(length));
    return violations;
  }

  int _availableFor(LeaveInput input, List<LeaveBalance> balances) {
    for (final balance in balances) {
      if (balance.type == input.type) return balance.available;
    }
    return 0;
  }
}
