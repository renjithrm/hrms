// lib/models/attendance_result.dart

import 'attendance_event_type.dart';

/// What the result sheet shows after a check-in or check-out.
class AttendanceResult {
  /// Creates the result.
  const AttendanceResult({
    required this.type,
    required this.timeLabel,
    required this.placeLabel,
    required this.isSynced,
  });

  /// Check-in or check-out.
  final AttendanceEventType type;

  /// Company-time time of the action, `HH:mm`.
  final String timeLabel;

  /// Office name.
  final String placeLabel;

  /// Whether the server already has it.
  final bool isSynced;
}
