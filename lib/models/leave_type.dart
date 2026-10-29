// lib/models/leave_type.dart

/// Kinds of leave an employee can apply for.
enum LeaveType {
  /// Planned personal leave.
  casual('CASUAL', 'Casual'),

  /// Illness.
  sick('SICK', 'Sick');

  const LeaveType(this.wireValue, this.label);

  /// Value used by the API and the database.
  final String wireValue;

  /// Display name.
  final String label;

  /// Parses [wireValue].
  static LeaveType fromWire(String value) => values.firstWhere(
        (type) => type.wireValue == value,
        orElse: () => throw FormatException('Unknown leave type', value),
      );
}
