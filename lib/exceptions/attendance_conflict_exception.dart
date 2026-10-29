// lib/exceptions/attendance_conflict_exception.dart

import 'api_exception.dart';

/// The server refused an attendance event (HTTP 409 or 422), for example
/// because attendance already exists for that day. Never retried.
class AttendanceConflictException extends ApiException {
  /// Creates the exception.
  const AttendanceConflictException({
    required this.code,
    required String message,
  }) : super(message);

  /// Machine-readable reason, for example `ATTENDANCE_EXISTS`.
  final String code;

  @override
  bool get isRetryable => false;
}
