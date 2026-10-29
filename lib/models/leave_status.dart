// lib/models/leave_status.dart

/// Review status of a leave request.
enum LeaveStatus {
  /// Waiting for the manager.
  pending('PENDING'),

  /// Granted.
  approved('APPROVED'),

  /// Refused.
  rejected('REJECTED');

  const LeaveStatus(this.wireValue);

  /// Value used by the API and the database.
  final String wireValue;

  /// Parses [wireValue].
  static LeaveStatus fromWire(String value) => values.firstWhere(
        (status) => status.wireValue == value,
        orElse: () => throw FormatException('Unknown leave status', value),
      );
}
