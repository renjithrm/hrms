// lib/models/attendance_day.dart

import 'sync_state.dart';

/// One working day as the person sees it: the server's record merged with
/// attendance taken on this device that the server may not have yet.
class AttendanceDay {
  /// Creates a day.
  const AttendanceDay({
    required this.workDate,
    this.checkInAt,
    this.checkOutAt,
    this.checkInState = SyncState.synced,
    this.checkOutState = SyncState.synced,
  });

  /// Company-timezone date, `yyyy-MM-dd`.
  final String workDate;

  /// Check-in time in UTC, if any.
  final DateTime? checkInAt;

  /// Check-out time in UTC, if any.
  final DateTime? checkOutAt;

  /// Whether the server has the check-in. [SyncState.synced] when it came
  /// from the server.
  final SyncState checkInState;

  /// Whether the server has the check-out.
  final SyncState checkOutState;

  /// Time worked, once both ends exist.
  Duration? get worked {
    final start = checkInAt;
    final end = checkOutAt;
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  /// Whether any part of the day is still only on this device.
  bool get isWaitingToSync =>
      (checkInAt != null && checkInState != SyncState.synced) ||
      (checkOutAt != null && checkOutState != SyncState.synced);
}
