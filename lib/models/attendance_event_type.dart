// lib/models/attendance_event_type.dart

/// The two attendance actions.
enum AttendanceEventType {
  /// Start of the working day.
  checkIn('CHECK_IN'),

  /// End of the working day.
  checkOut('CHECK_OUT');

  const AttendanceEventType(this.wireValue);

  /// Value used by the API and the database.
  final String wireValue;

  /// Parses [wireValue].
  static AttendanceEventType fromWire(String value) => values.firstWhere(
        (type) => type.wireValue == value,
        orElse: () => throw FormatException('Unknown event type', value),
      );
}
