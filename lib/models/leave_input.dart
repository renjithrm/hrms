// lib/models/leave_input.dart

import '../extensions/date_time_extensions.dart';
import 'leave_type.dart';

/// What the person has entered in the leave form so far.
class LeaveInput {
  /// Creates form input.
  const LeaveInput({
    required this.type,
    this.startDate,
    this.endDate,
    this.reason = '',
  });

  /// Casual or sick.
  final LeaveType type;

  /// First day, if chosen.
  final DateTime? startDate;

  /// Last day, if chosen.
  final DateTime? endDate;

  /// Reason text as typed.
  final String reason;

  /// Calendar days requested, when both dates are chosen and in order.
  int? get days {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null || end.isBefore(start)) return null;
    return start.daysUntil(end) + 1;
  }

  /// Reason length without any whitespace, as the brief defines it.
  int get reasonLength => reason.replaceAll(RegExp(r'\s'), '').length;

  /// Body for `POST /leave/requests`. Call only when both dates are set.
  Map<String, dynamic> toApiJson() => {
        'type': type.wireValue,
        'startDate': startDate?.isoDate,
        'endDate': endDate?.isoDate,
        'reason': reason.trim(),
      };
}
