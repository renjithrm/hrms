// lib/models/attendance_record.dart

/// One working day as the server knows it.
class AttendanceRecord {
  /// Creates a record.
  const AttendanceRecord({
    required this.workDate,
    this.checkInAt,
    this.checkOutAt,
  });

  /// Reads the API shape.
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        workDate: json['workDate'] as String,
        checkInAt: _parse(json['checkInAt']),
        checkOutAt: _parse(json['checkOutAt']),
      );

  /// Company-timezone date, `yyyy-MM-dd`.
  final String workDate;

  /// Check-in time in UTC, if any.
  final DateTime? checkInAt;

  /// Check-out time in UTC, if any.
  final DateTime? checkOutAt;

  /// Time worked, once both ends exist.
  Duration? get worked {
    final start = checkInAt;
    final end = checkOutAt;
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  /// Serialises to the API shape, also used for the local cache.
  Map<String, dynamic> toJson() => {
        'workDate': workDate,
        'checkInAt': checkInAt?.toUtc().toIso8601String(),
        'checkOutAt': checkOutAt?.toUtc().toIso8601String(),
      };

  static DateTime? _parse(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toUtc();
}
