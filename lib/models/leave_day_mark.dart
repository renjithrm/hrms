// lib/models/leave_day_mark.dart

/// An existing request drawn on the leave range calendar, so overlaps are
/// visible before they become an error.
enum LeaveDayMark {
  /// Covered by a pending request.
  pending,

  /// Covered by approved leave.
  approved,
}
